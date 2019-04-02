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
            
            let env = SettingsStore.environment.value
            
            guard env != "prod" else {
                return "https://rhythmic-rebellion.com"
            }
            
            let `protocol` = env == "staging" ? "https" : "http"
            
            return "\(`protocol`)://\(String(describing: env)).fan.rebellionretailsite.com"
        }
        
        static var restApiService: String {
            
            let env = SettingsStore.environment.value
            
            guard env != "prod" else {
                return "https://api.rhythmic-rebellion.com"
            }
            
            let `protocol` = env == "staging" ? "https" : "http"
            
            return "\(`protocol`)://\(String(describing: env)).api.rebellionretailsite.com"
            
        }
        
        static var webSocketService: String {
            
            let env = SettingsStore.environment.value
            
            guard env != "prod" else {
                return "wss://ws.rebellion-services.com"
            }
            
            guard env != "staging" else {
                return "wss://staging.ws.rebellionretailsite.com:3000/"
            }
            
            return "ws://\(String(describing: env)).rebellionretailsite.com:3000/"
        }
        
    }

    let restApiService: RestApiService
    let webSocketService: WebSocketService
    let pagesLocalStorageService = PagesLocalStorageService()
    
    
    let restApiServiceReachability: Reachability?
    
    

    private var needsLoadUser: Bool = false

    var user: User? = nil
    
    var config: Config?

    init?() {
        guard let restApiService = RestApiService(serverURI: URI.restApiService, originURI: URI.origin) else { return nil }
        
        let webSocketService = WebSocketService(url: URI.webSocketService)
        
        self.restApiService = restApiService
        self.webSocketService = webSocketService

        self.restApiServiceReachability = Reachability(hostname: restApiService.serverURL.host!)
        
        self.restApiServiceReachability?.whenReachable = { [unowned self] _ in
            if self.config == nil { self.loadConfig() }
            if self.user == nil || self.needsLoadUser {

                let _ =
                UserRequest.login.rx.baseResponse(type: User.self)
                    .subscribe(onSuccess: { (user) in
                        Dispatcher.dispatch(action: SetNewUser(user: user))
                    })
                
            }

            self.watchersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: true)
            })
        }

        self.restApiServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.watchersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: false)
            })
        }

    }

    func start() {
        _ = try? self.restApiServiceReachability?.startNotifier()
    }

    func loadConfig(completion: ((Result<Config>) -> Void)? = nil) {

        let _ =
        ConfigRequest.user.rx.baseResponse(type: Config.self)
            .subscribe(onSuccess: { (config) in
                completion?( .success(config) )
            })
        
    }

    func set(user: User) {

        guard let prevUser = self.user else {
            self.user = user
            
            if let fanUser = user as? User {
                SettingsStore.lastSignedUserEmail.value = fanUser.profile?.email
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
            
            SettingsStore.lastSignedUserEmail.value = user.profile?.email
            
            DownloadManager.default.clearArtifacts()
            self.pagesLocalStorageService.reset()
            self.notifyUserChanged()
        } else {
            if prevUser.profile != user.profile {

                self.notifyUserProfileChanged()
            }

            if prevUser.wsToken != user.wsToken {
                self.notifyUserTokenChanged()
            }
        }

        self.needsLoadUser = false
    }

    

    // MARK: Tracks

    func allowPlayTrackWithExplicitMaterial(trackId: Int, shouldAllow: Bool, completion: ((Result<[Int]>) -> Void)? = nil) {

        

        self.restApiService.fanAllowPlayTrackWithExplicitMaterial(trackId: trackId, shouldAllow: shouldAllow) { [weak self] (allowPlayTrackResult) in

            switch allowPlayTrackResult {
            case .success(let trackForceToPlayState):
                
                var nextFanUser = self?.user
                nextFanUser?.profile?.update(with: trackForceToPlayState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: trackForceToPlayState))

                self?.notifyUserProfileForceToPlayChanged(with: trackForceToPlayState)
                
                completion?(.success(Array(nextFanUser?.profile?.forceToPlay ?? [])))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }


    func updateSkipAddons(for artist: Artist, skip: Bool, completion: @escaping (Error?) -> Void) {

        self.restApiService.updateSkipArtistAddons(for: artist, skip: skip) { [weak self] (skipArtistAddonsResult) in
            switch skipArtistAddonsResult {
            case .success(let updatedUser):
                self?.set(user: updatedUser)
                
                let skipArtistAddonsState = SkipArtistAddonsState(artistId: artist.id,
                                                                  isSkipped: updatedUser.isAddonsSkipped(for: artist))
                
                self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: skipArtistAddonsState))

                self?.notifyUserProfileSkipAddonsArtistsIdsChanged(with: skipArtistAddonsState)
                completion(nil)

            case .failure(let error):
                completion(error)
            }
        }

    }

    func update(track: Track, likeState: Track.LikeStates, completion: ((Error?) -> Void)? = nil) {
        

        self.restApiService.fanUpdate(track: track, likeState: likeState) { [weak self] (trackLikeStateResult) in
            switch trackLikeStateResult {
            case .success(let trackLikeState):

                var nextFanUser = self?.user
                nextFanUser?.profile?.update(with: trackLikeState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: trackLikeState))

                self?.notifyUserProfileTraksLikeStetesChanged(with: trackLikeState)
                completion?(nil)

            case .failure(let error): completion?(error)
            }
        }
    }

    // MARK: Artists
    func follow(shouldFollow: Bool, artistId: String, completion: ((Error?) -> Void)? = nil) {
        

        self.restApiService.fanFollow(shouldFollow: shouldFollow, artistId: artistId) { [weak self] (followArtistResult) in

            switch followArtistResult {
            case .success(let artistFollowingState):

                var nextFanUser = self?.user
                nextFanUser?.profile?.update(with: artistFollowingState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: artistFollowingState))

                self?.notifyUserProfileFollowedArtistsIdsChanged(with: artistFollowingState)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        }
    }


    // MARK: Fan Playlists

    func createPlaylist(with name: String, completion: @escaping (Result<FanPlaylist>) -> Void) {
        

        self.restApiService.fanCreatePlaylist(with: name) { [weak self] (fanPlaylistResult) in
            switch fanPlaylistResult {
            case .success(let fanPlaylist):

                let fanPlaylistState = FanPlaylistState(id: fanPlaylist.id, playlist: fanPlaylist)
                self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: fanPlaylistState))

                self?.notifyFanPlaylistChanged(with: fanPlaylistState)

            default: break
            }

            completion(fanPlaylistResult)
        }
    }

    func delete(playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        
        self.restApiService.fanDelete(playlist: playlist) { [weak self] (error) in
            guard error == nil else { completion(error); return }

            let fanPlaylistState = FanPlaylistState(id: playlist.id, playlist: nil)
            self?.webSocketService.sendCommand(command: CodableWebSocketCommand(data: fanPlaylistState))

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
        

//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: fanUser.profile)
//        })
    }

    func notifyUserProfileListeningSettingsChanged() {
        

//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: fanUser.profile?.listeningSettings)
//        })
    }

    func notifyUserProfileForceToPlayChanged(with trackForceToPlayState: TrackForceToPlayState) {
        

//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: Array(fanUser.profile?.forceToPlay), with: trackForceToPlayState)
//        })
    }

    func notifyUserProfileFollowedArtistsIdsChanged(with artistFollowingState: ArtistFollowingState) {
        

//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: Array(fanUser.profile?.followedArtistsIds), with: artistFollowingState)
//        })
        
        followingStateSubject.on( .next(artistFollowingState) )
    }

    func notifyUserProfileSkipAddonsArtistsIdsChanged(with skipArtistAddonsState: SkipArtistAddonsState) {
        

//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: Array(fanUser.profile?.skipAddonsArtistsIds), with: skipArtistAddonsState)
//        })
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
        
//        self.watchersContainer.invoke({ (observer) in
//            observer.application(self, didChangeUserProfile: fanUser.profile?.tracksLikeStates, with: trackLikeState)
//        })
    }
}

///TODO: handle responses from WebSocket
extension Application {

//    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings) {
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.listeningSettings = listeningSettings
//        self.user = fanUser
//
//        self.notifyUserProfileListeningSettingsChanged()
//    }
//
//    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState) {
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.update(with: trackForceToPlayState)
//        self.user = fanUser
//
//        self.notifyUserProfileForceToPlayChanged(with: trackForceToPlayState)
//    }
//
//    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState) {
//
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.update(with: artistFollowingState)
//        self.user = fanUser
//
//        self.notifyUserProfileFollowedArtistsIdsChanged(with: artistFollowingState)
//    }
//
//    func webSocketService(_ service: WebSocketService, didReceiveSkipArtistAddonsState skipArtistAddonsState: SkipArtistAddonsState) {
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.update(with: skipArtistAddonsState)
//        self.user = fanUser
//
//        self.notifyUserProfileSkipAddonsArtistsIdsChanged(with: skipArtistAddonsState)
//    }
//
//    func webSocketService(_ service: WebSocketService, didReceivePurchases purchases: [Purchase]) {
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.update(with: purchases)
//        self.user = fanUser
//
//        notifyUserProfileChanged(purchasedTracksIds: fanUser.profile?.purchasedTracksIds,
//                                 previousPurchasedTracksIds: currentFanUser.profile.purchasedTracksIds)
//    }
//
//    func webSocketService(_ service: WebSocketService, didRecieveFanPlaylistState fanPlaylistState: FanPlaylistState) {
//        guard (self.user as? User) != nil else { return }
//
//        notifyFanPlaylistChanged(with: fanPlaylistState)
//    }
//
//    func webSocketService(_ service: WebSocketService, didReceiveTrackLikeState trackLikeState: TrackLikeState) {
//        guard let currentFanUser = self.user as? User else { return }
//
//        var fanUser = currentFanUser
//        fanUser.profile?.update(with: trackLikeState)
//        self.user = fanUser
//
//        self.notifyUserProfileTraksLikeStetesChanged(with: trackLikeState)
//    }
}
