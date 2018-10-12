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

protocol UserCredentials {
    var email: String { get }
    var password: String { get }
}

protocol ApplicationObserver: class {

    func application(_ application: Application, restApiServiceDidChangeReachableState isReachable: Bool)

    func application(_ application: Application, didChange user: User)
    func application(_ application: Application, didChange listeningSettings: ListeningSettings)
    func application(_ application: Application, didChange profile: UserProfile)
    func application(_ application: Application, didChange followedArtistsIds: [String])
}

extension ApplicationObserver {
    func application(_ application: Application, restApiServiceDidChangeReachableState isReachable: Bool) { }
    
    func application(_ application: Application, didChange user: User) { }
    func application(_ application: Application, didChange listeningSettings: ListeningSettings) { }
    func application(_ application: Application, didChange profile: UserProfile) { }
    func application(_ application: Application, didChange followedArtistsIds: [String]) { }
}

class Application: Observable {

    typealias ObserverType = ApplicationObserver

    let observersContainer = ObserversContainer<ApplicationObserver>()

    struct URI {

        //http://mobile.fan.rebellionretailsite.com/

        static let origin = "http://dev-mobile.fan.rebellionretailsite.com"
        static let restApiService = "http://dev-mobile.api.rebellionretailsite.com"
        static let webSocketService = "ws://dev-mobile.rebellionretailsite.com:3000/"
    }

    let restApiService: RestApiService
    let webSocketService: WebSocketService

    private let restApiServiceReachability: Reachability?
    private let webSocketServiceReachability: Reachability?

    let audioFileLocalStorageService: AudioFileLocalStorageService

    var user: User? = nil
    var config: Config?

    init?() {
        guard let restApiService = RestApiService(serverURI: URI.restApiService, originURI: URI.origin), let webSocketService = WebSocketService(webSocketURI: URI.webSocketService) else { return nil }

        self.restApiService = restApiService
        self.webSocketService = webSocketService

        self.audioFileLocalStorageService = AudioFileLocalStorageService()

        self.restApiServiceReachability = Reachability(hostname: restApiService.serverURL.host!)
        self.webSocketServiceReachability = Reachability(hostname: webSocketService.webSocketURL.host!)

        self.restApiServiceReachability?.whenReachable = { [unowned self] _ in
            if self.config == nil { self.loadConfig() }
            if self.user == nil { self.fanUser() }

            self.observersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: true)
            })
        }

        self.restApiServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.observersContainer.invoke({ (observer) in
                observer.application(self, restApiServiceDidChangeReachableState: false)
            })
        }

        self.webSocketServiceReachability?.whenReachable = { [unowned self] _ in
            self.webSocketService.isReachable = true
            guard let user = self.user else { return }
            self.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
        }

        self.webSocketServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.webSocketService.isReachable = false
            self.webSocketService.disconnect()
        }

        self.webSocketService.addObserver(self)
    }

    func start() {
        _ = try? self.webSocketServiceReachability?.startNotifier()
        _ = try? self.restApiServiceReachability?.startNotifier()
    }

    func loadConfig(completion: ((Result<Config>) -> Void)? = nil) {

        self.restApiService.config { [weak self] (configResult) in

            switch configResult {
            case .success(let config):
                self?.config = config

            default: break
            }

            completion?(configResult)
        }
    }

    func set(user: User) {

        guard let prevUser = self.user else {
            self.user = user
            self.notifyUserChanged()
            return
        }

        self.user = user

        if prevUser != user {
            self.notifyUserChanged()
        } else {
            if let prevFanUser = prevUser as? FanUser,
                    let fanUser = user as? FanUser,
                prevFanUser.profile != fanUser.profile {

                self.notifyUserProfileChanged()
            }

            if self.webSocketService.token?.token != user.wsToken {
                self.webSocketService.token = Token(token: user.wsToken, isGuest: user.isGuest)
            }
        }
    }

    func fanUser(completion: ((Result<User>) -> Void)? = nil) {
        self.restApiService.fanUser { [weak self] (fanUserResult) in

            switch (fanUserResult) {
            case .success(let user):
                self?.set(user: user)
                completion?(.success(user))

            case .failure(let error):
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
                self?.notifyListeningSettingsChanged()
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

    func allowPlayTrackWithExplicitMaterial(track: Track, completion: ((Result<[Int]>) -> Void)? = nil) {

        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanAllowPlayTrackWithExplicitMaterial(track: track) { [weak self] (allowPlayTrackResult) in

            switch allowPlayTrackResult {
            case .success(let trackForceToPlayState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: trackForceToPlayState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncForceToPlay(trackForceToPlayState: trackForceToPlayState))

                completion?(.success(Array(nextFanUser.profile.forceToPlay)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func disallowPlayTrackWithExplicitMaterial(track: Track, completion: ((Result<[Int]>) -> Void)? = nil) {

        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanDisallowPlayTrackWithExplicitMaterial(track: track) { [weak self] (allowPlayTrackResult) in

            switch allowPlayTrackResult {
            case .success(let trackForceToPlayState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: trackForceToPlayState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncForceToPlay(trackForceToPlayState: trackForceToPlayState))

                completion?(.success(Array(nextFanUser.profile.forceToPlay)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func follow(artist: Artist, completion: ((Result<[String]>) -> Void)? = nil) {
        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanFollow(artist: artist) { [weak self] (followArtistResult) in

            switch followArtistResult {
            case .success(let artistFollowingState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: artistFollowingState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncFollowing(artistFollowingState: artistFollowingState))

                self?.notifyUserFollowedArtistsIdsChanged()
                completion?(.success(Array(nextFanUser.profile.followedArtistsIds)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func unfollow(artist: Artist, completion: ((Result<[String]>) -> Void)? = nil) {
        guard let fanUser = self.user as? FanUser else { return }

        self.restApiService.fanUnfollow(artist: artist) { [weak self] (unfollowArtistResult) in

            switch unfollowArtistResult {
            case .success(let artistFollowingState):
                guard let currentFanUser = self?.user as? FanUser, currentFanUser == fanUser else { return }

                var nextFanUser = currentFanUser
                nextFanUser.profile.update(with: artistFollowingState)
                self?.user = nextFanUser

                self?.webSocketService.sendCommand(command: WebSocketCommand.syncFollowing(artistFollowingState: artistFollowingState))

                self?.notifyUserFollowedArtistsIdsChanged()
                completion?(.success(Array(nextFanUser.profile.followedArtistsIds)))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

}

extension Application {

    func notifyUserChanged() {

        guard let user = self.user else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: user)
        })
    }

    func notifyListeningSettingsChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: fanUser.profile.listeningSettings)
        })
    }

    func notifyUserProfileChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: fanUser.profile)
        })
    }

    func notifyUserFollowedArtistsIdsChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: Array(fanUser.profile.followedArtistsIds))
        })
    }
}

extension Application: WebSocketServiceObserver {

    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.listeningSettings = listeningSettings
        self.user = fanUser

        self.notifyListeningSettingsChanged()
    }

    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState) {
        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: trackForceToPlayState)
        self.user = fanUser
    }

    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState) {

        guard let currentFanUser = self.user as? FanUser else { return }

        var fanUser = currentFanUser
        fanUser.profile.update(with: artistFollowingState)
        self.user = fanUser

        self.notifyUserFollowedArtistsIdsChanged()
    }
}
