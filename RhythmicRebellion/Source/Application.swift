//
//  Application.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Reachability
import Alamofire
import RxSwift

protocol UserCredentials {
    var email: String { get }
    var password: String { get }
}

protocol ApplicationWatcher: class {

    func application(_ application: Application, restApiServiceDidChangeReachableState isReachable: Bool)

    func application(_ application: Application, didChange user: User)
    func application(_ application: Application, didChangeUserToken user: User)

    func application(_ application: Application, didChangeUserProfile userProfile: UserProfile)
    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings)
    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState)
    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState)
    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState)
    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int])
    func application(_ application: Application, didChangeUserProfile tracksLikeStates: [Int : Track.LikeStates], with trackLikeState: TrackLikeState)

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState)
}

extension ApplicationWatcher {
    func application(_ application: Application, restApiServiceDidChangeReachableState isReachable: Bool) { }
    
    func application(_ application: Application, didChange user: User) { }
    func application(_ application: Application, didChangeUserToken user: User) { }

    func application(_ application: Application, didChangeUserProfile userProfile: UserProfile) { }
    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) { }
    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) { }
    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) { }
    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState) { }
    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) { }
    func application(_ application: Application, didChangeUserProfile tracksLikeStates: [Int : Track.LikeStates], with trackLikeState: TrackLikeState) { }

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) { }
}

class Application: Watchable {

    typealias WatchType = ApplicationWatcher

    let watchersContainer = WatchersContainer<ApplicationWatcher>()

    ////TODO: move watcherContainer to strongly typed Observable Commands
    ////WebSocketCommand<T>
    
    fileprivate let followingStateSubject = BehaviorSubject<ArtistFollowingState?>(value: nil)
    var followingState: Observable<ArtistFollowingState> {
        return followingStateSubject.asObservable().skip(1).notNil()
    }
    
    struct URI {

        static var origin: String {
            
            let env = Defaults.Env
            
            guard env != "prod" else {
                return "https://rhythmic-rebellion.com"
            }
            
            return "http://\(String(describing: env)).fan.rebellionretailsite.com"
        }
        
        static var restApiService: String {
            
            let env = Defaults.Env
            
            guard env != "prod" else {
                return "https://api.rhythmic-rebellion.com"
            }
            
            return "http://\(String(describing: env)).fan.rebellionretailsite.com"
            
        }
        
        static var webSocketService: String {
            
            let env = Defaults.Env
            
            guard env != "prod" else {
                return "wss://ws.rebellion-services.com"
            }
            
            return "ws://\(String(describing: env)).rebellionretailsite.com:3000/"
        }
        
    }
    
    let restApiService: RestApiService
    let webSocketService: WebSocketService

    let restApiServiceReachability: Reachability?
    private let webSocketServiceReachability: Reachability?

    let pagesLocalStorageService : PagesLocalStorageService

    let disableIdleTimerSubscription: Observable<Void>

    private var needsLoadUser: Bool = false

    var user: User? = nil
    var config: Config?

    init?() {
        guard let restApiService = RestApiService(serverURI: URI.restApiService, originURI: URI.origin), let webSocketService = WebSocketService(webSocketURI: URI.webSocketService) else { return nil }

        self.restApiService = restApiService
        self.webSocketService = webSocketService

        self.pagesLocalStorageService = PagesLocalStorageService()

        self.restApiServiceReachability = Reachability(hostname: restApiService.serverURL.host!)
        self.webSocketServiceReachability = Reachability(hostname: webSocketService.webSocketURL.host!)

        self.disableIdleTimerSubscription = Observable<Void>.create({ (observer) -> Disposable in
                UIApplication.shared.isIdleTimerDisabled = true
                return Disposables.create {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            })
            .share()


        self.restApiServiceReachability?.whenReachable = { [unowned self] _ in
            if self.config == nil { self.loadConfig() }
            if self.user == nil || self.needsLoadUser { self.fanUser() }

            self.watchersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: true)
            })
        }

        self.restApiServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.watchersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: false)
            })
        }

        self.webSocketServiceReachability?.whenReachable = { [unowned self] _ in
            self.webSocketService.isReachable = true
            guard let user = self.user, self.webSocketService.state == .disconnected else { return }
            self.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
        }

        self.webSocketServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.webSocketService.isReachable = false
            self.webSocketService.disconnect()
        }

        self.webSocketService.addWatcher(self)
    }

    func start() {
        _ = try? self.webSocketServiceReachability?.startNotifier()
        _ = try? self.restApiServiceReachability?.startNotifier()
    }

    func loadConfig(completion: ((Result<Config>) -> Void)? = nil) {

        self.restApiService.config { [weak self] (configResult) in

            switch configResult {
            case .success(let config): self?.config = config
            default: break
            }

            completion?(configResult)
        }
    }

    func set(user: User) {

        guard let prevUser = self.user else {
            self.user = user
            if let fanUser = user as? FanUser {
                Defaults.lastSignedUserEmail = fanUser.profile.email
            } else {
                DownloadManager.default.clearArtifacts()
                self.pagesLocalStorageService.reset()
            }

            self.notifyUserChanged()
            self.needsLoadUser = false
            return
        }

        self.user = user

        if prevUser != user {
            if let fanUser = user as? FanUser {
                Defaults.lastSignedUserEmail = fanUser.profile.email
            }

            DownloadManager.default.clearArtifacts()
            self.pagesLocalStorageService.reset()
            self.notifyUserChanged()
        } else {
            if let prevFanUser = prevUser as? FanUser,
                    let fanUser = user as? FanUser,
                prevFanUser.profile != fanUser.profile {

                self.notifyUserProfileChanged()
            }

            if prevUser.wsToken != user.wsToken {
                self.notifyUserTokenChanged()
            }
        }

        self.needsLoadUser = false
    }

    func fanUser(completion: ((Result<User>) -> Void)? = nil) {
        self.restApiService.fanUser { [weak self] (fanUserResult) in

            switch (fanUserResult) {
            case .success(let user):
                self?.set(user: user)
                completion?(.success(user))

            case .failure(let error):
                if self?.restApiServiceReachability?.connection == Reachability.Connection.none {
                    self?.needsLoadUser = true
                }
                completion?(.failure(error))
            }
        }

    }

    func signIn(with credentials: UserCredentials, completion: ((Error?) -> Void)? = nil) {

        self.restApiService.fanLogin(email: credentials.email, password: credentials.password, completion: { [weak self] (loginUserResult) in

            switch (loginUserResult) {
            case .success(let user):
                self?.set(user: user)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        })
    }

    func logout(completion: ((Error?) -> Void)? = nil) {
        guard let user = self.user, user.isGuest == false else { return }

        self.restApiService.fanLogout { [weak self] (logoutUserResult) in
            switch logoutUserResult {
            case .success(let user):
                self?.set(user: user)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        }
    }

    func update(listeningSettings: ListeningSettings, completion: ((Result<ListeningSettings>) -> Void)? = nil) {

        guard let user = self.user, user.isGuest == false else { return }

        let listeningSettingsRequestPayload = RestApiListeningSettingsRequestPayload(with: listeningSettings)

        self.restApiService.fanUser(update: listeningSettingsRequestPayload) { [weak self] (updateUserResult) in

            switch updateUserResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { completion?(.failure(AppError("Unexpected Server response"))); return }

                self?.set(user: user)
                self?.webSocketService.sendCommand(command: WebSocketCommand.syncListeningSettings(listeningSettings: fanUser.profile.listeningSettings))
                self?.notifyUserProfileListeningSettingsChanged()
                completion?(.success(fanUser.profile.listeningSettings))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func update(profileSettings: UserProfile, completion: ((Result<UserProfile>) -> Void)? = nil) {

        guard let user = self.user, user.isGuest == false else { return }

        let profileSettingsRequestPayload = RestApiProfileSettingsRequestPayload(with: profileSettings)

        self.restApiService.fanUser(update: profileSettingsRequestPayload) { [weak self] (updateUserResult) in

            switch updateUserResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { completion?(.failure(AppError("Unexpected Server response"))); return }

                self?.set(user: user)
                completion?(.success(fanUser.profile))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func changePassword(currentPassword: String, newPassword: String, newPasswordConfirmation: String, completion: ((Result<User>) -> Void)? = nil) {
        guard let user = self.user, user.isGuest == false else { return }

        let changePasswordRequestPayload = RestApiFanUserChangePasswordRequestPayload(currentPassword: currentPassword,
                                                                                      newPassword: newPassword,
                                                                                      newPasswordConfirmation: newPasswordConfirmation)

        self.restApiService.fanUser(changePassword: changePasswordRequestPayload) { [weak self] (changePasswordResult) in

            switch changePasswordResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { completion?(.failure(AppError("Unexpected Server response"))); return }

                self?.set(user: fanUser)
                completion?(.success(fanUser))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    // MARK: Tracks

    func allowPlayTrackWithExplicitMaterial(trackId: Int, completion: ((Result<[Int]>) -> Void)? = nil) {

        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanAllowPlayTrackWithExplicitMaterial(trackId: trackId) { [weak self] (allowPlayTrackResult) in

            switch allowPlayTrackResult {
            case .success(let trackForceToPlayState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: trackForceToPlayState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncForceToPlay(trackForceToPlayState: trackForceToPlayState))

                self?.notifyUserProfileForceToPlayChanged(with: trackForceToPlayState)
                completion?(.success(Array(nextFanUser.profile.forceToPlay)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func disallowPlayTrackWithExplicitMaterial(trackId: Int, completion: ((Result<[Int]>) -> Void)? = nil) {

        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanDisallowPlayTrackWithExplicitMaterial(trackId: trackId) { [weak self] (allowPlayTrackResult) in

            switch allowPlayTrackResult {
            case .success(let trackForceToPlayState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: trackForceToPlayState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncForceToPlay(trackForceToPlayState: trackForceToPlayState))

                self?.notifyUserProfileForceToPlayChanged(with: trackForceToPlayState)
                completion?(.success(Array(nextFanUser.profile.forceToPlay)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func updateSkipAddons(for artist: Artist, skip: Bool, completion: @escaping (Error?) -> Void) {

        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.updateSkipArtistAddons(for: artist, skip: skip) { [weak self] (skipArtistAddonsResult) in
            switch skipArtistAddonsResult {
            case .success(let updatedUser):
                self?.set(user: updatedUser)
                guard let updatedFanUser = updatedUser as? FanUser, fanUser == updatedFanUser else { completion(nil); return }

                let skipArtistAddonsState = SkipArtistAddonsState(artistId: artist.id, isSkipped: updatedFanUser.isAddonsSkipped(for: artist))
                self?.webSocketService.sendCommand(command: WebSocketCommand.syncArtistAddonsState(skipArtistAddonsState: skipArtistAddonsState))

                self?.notifyUserProfileSkipAddonsArtistsIdsChanged(with: skipArtistAddonsState)
                completion(nil)

            case .failure(let error):
                completion(error)
            }
        }

    }

    func update(track: Track, likeState: Track.LikeStates, completion: ((Error?) -> Void)? = nil) {
        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanUpdate(track: track, likeState: likeState) { [weak self] (trackLikeStateResult) in
            switch trackLikeStateResult {
            case .success(let trackLikeState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: trackLikeState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncTrackLikeState(trackLikeState: trackLikeState))

                self?.notifyUserProfileTraksLikeStetesChanged(with: trackLikeState)
                completion?(nil)

            case .failure(let error): completion?(error)
            }
        }
    }

    // MARK: Artists
    func follow(artistId: String, completion: ((Result<[String]>) -> Void)? = nil) {
        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanFollow(artistId: artistId) { [weak self] (followArtistResult) in

            switch followArtistResult {
            case .success(let artistFollowingState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: artistFollowingState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncFollowing(artistFollowingState: artistFollowingState))

                self?.notifyUserProfileFollowedArtistsIdsChanged(with: artistFollowingState)
                completion?(.success(Array(nextFanUser.profile.followedArtistsIds)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func unfollow(artistId: String, completion: ((Result<[String]>) -> Void)? = nil) {
        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanUnfollow(artistId: artistId) { [weak self] (unfollowArtistResult) in

            switch unfollowArtistResult {
            case .success(let artistFollowingState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: artistFollowingState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncFollowing(artistFollowingState: artistFollowingState))

                self?.notifyUserProfileFollowedArtistsIdsChanged(with: artistFollowingState)
                completion?(.success(Array(nextFanUser.profile.followedArtistsIds)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    // MARK: Fan Playlists

    func createPlaylist(with name: String, completion: @escaping (Result<FanPlaylist>) -> Void) {
        guard (self.user as? FanUser) != nil else { return }

        self.restApiService.fanCreatePlaylist(with: name) { [weak self] (fanPlaylistResult) in
            switch fanPlaylistResult {
            case .success(let fanPlaylist):

                let fanPlaylistState = FanPlaylistState(id: fanPlaylist.id, playlist: fanPlaylist)
                self?.webSocketService.sendCommand(command: WebSocketCommand.fanPlaylistsStates(for: fanPlaylistState))

                self?.notifyFanPlaylistChanged(with: fanPlaylistState)

            default: break
            }

            completion(fanPlaylistResult)
        }
    }

    func delete(playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        guard (self.user as? FanUser) != nil else { return }

        self.restApiService.fanDelete(playlist: playlist) { [weak self] (error) in
            guard error == nil else { completion(error); return }

            let fanPlaylistState = FanPlaylistState(id: playlist.id, playlist: nil)
            self?.webSocketService.sendCommand(command: WebSocketCommand.fanPlaylistsStates(for: fanPlaylistState))

            self?.notifyFanPlaylistChanged(with: fanPlaylistState)

            completion(nil)
        }
    }

}

extension Application {

    func notifyUserChanged() {

        guard let user = self.user else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChange: user)
        })
    }

    func notifyUserTokenChanged() {
        guard let user = self.user else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserToken: user)
        })
    }

    func notifyUserProfileChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: fanUser.profile)
        })
    }

    func notifyUserProfileListeningSettingsChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: fanUser.profile.listeningSettings)
        })
    }

    func notifyUserProfileForceToPlayChanged(with trackForceToPlayState: TrackForceToPlayState) {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: Array(fanUser.profile.forceToPlay), with: trackForceToPlayState)
        })
    }

    func notifyUserProfileFollowedArtistsIdsChanged(with artistFollowingState: ArtistFollowingState) {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: Array(fanUser.profile.followedArtistsIds), with: artistFollowingState)
        })
        
        followingStateSubject.on( .next(artistFollowingState) )
    }

    func notifyUserProfileSkipAddonsArtistsIdsChanged(with skipArtistAddonsState: SkipArtistAddonsState) {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: Array(fanUser.profile.skipAddonsArtistsIds), with: skipArtistAddonsState)
        })
    }

    func notifyUserProfileChanged(purchasedTracksIds: Set<Int>, previousPurchasedTracksIds: Set<Int>) {

        guard purchasedTracksIds != previousPurchasedTracksIds else { return }

        let addedPurchasedTracksIds = Array(purchasedTracksIds.subtracting(previousPurchasedTracksIds))
        let removedPurchasedTracksIds = Array(previousPurchasedTracksIds.subtracting(purchasedTracksIds))

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: Array(purchasedTracksIds), added: addedPurchasedTracksIds, removed: removedPurchasedTracksIds)
        })
    }

    func notifyFanPlaylistChanged(with fanPlaylistState: FanPlaylistState) {
        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeFanPlaylist: fanPlaylistState)
        })
    }

    func notifyUserProfileTraksLikeStetesChanged(with trackLikeState: TrackLikeState) {
        guard let fanUser = self.user as? FanUser else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.application(self, didChangeUserProfile: fanUser.profile.tracksLikeStates, with: trackLikeState)
        })
    }
}

extension Application: WebSocketServiceWatcher {

    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.listeningSettings = listeningSettings
        self.user = fanUser

        self.notifyUserProfileListeningSettingsChanged()
    }

    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: trackForceToPlayState)
        self.user = fanUser

        self.notifyUserProfileForceToPlayChanged(with: trackForceToPlayState)
    }

    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState) {

        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: artistFollowingState)
        self.user = fanUser

        self.notifyUserProfileFollowedArtistsIdsChanged(with: artistFollowingState)
    }

    func webSocketService(_ service: WebSocketService, didReceiveSkipArtistAddonsState skipArtistAddonsState: SkipArtistAddonsState) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: skipArtistAddonsState)
        self.user = fanUser

        self.notifyUserProfileSkipAddonsArtistsIdsChanged(with: skipArtistAddonsState)
    }

    func webSocketService(_ service: WebSocketService, didReceivePurchases purchases: [Purchase]) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: purchases)
        self.user = fanUser

        notifyUserProfileChanged(purchasedTracksIds: fanUser.profile.purchasedTracksIds,
                                 previousPurchasedTracksIds: currentFanUser.profile.purchasedTracksIds)
    }

    func webSocketService(_ service: WebSocketService, didRecieveFanPlaylistState fanPlaylistState: FanPlaylistState) {
        guard (self.user as? FanUser) != nil else { return }

        notifyFanPlaylistChanged(with: fanPlaylistState)
    }

    func webSocketService(_ service: WebSocketService, didReceiveTrackLikeState trackLikeState: TrackLikeState) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: trackLikeState)
        self.user = fanUser

        self.notifyUserProfileTraksLikeStetesChanged(with: trackLikeState)
    }
}
