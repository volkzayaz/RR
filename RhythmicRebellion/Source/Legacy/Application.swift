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

    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int])
    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState)
}

extension ApplicationWatcher {
    
    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) { }
    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) { }
}

class Application: Watchable {

    typealias WatchType = ApplicationWatcher

    let watchersContainer = WatchersContainer<ApplicationWatcher>()
    
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

        }

        self.restApiServiceReachability?.whenUnreachable = { [unowned self] _ in
            
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

extension Application { /// UserManager
    
    func allowPlayTrackWithExplicitMaterial(trackId: Int, shouldAllow: Bool) -> Maybe<Void> {
     
        return UserRequest.allowExplicitMaterial(trackId: trackId, shouldAllow: shouldAllow)
            .rx.response(type: TrackForceToPlayState.self)
            .do(onNext: { (newState) in
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user?.profile?.update(with: newState)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: newState))
            })
            .map { _ in () }
        
    }
    
    func updateSkipAddons(for artist: Artist, skip: Bool) -> Maybe<Void> {
        
        return UserRequest.skipAddonRule(for: artist, shouldSkip: skip)
            .rx.baseResponse(type: User.self)
            .do(onNext: { (user) in
                
                Dispatcher.dispatch(action: SetNewUser(user: user))
                
                let skipArtistAddonsState = SkipArtistAddonsState(artistId: artist.id,
                                                                  isSkipped: user.isAddonsSkipped(for: artist))
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: skipArtistAddonsState))
            })
            .map { _ in () }
        
    }
    
    func update(track: Track, likeState: Track.LikeStates) -> Maybe<Void> {
        
        return UserRequest.like(track: track, state: likeState)
            .rx.response(type: TrackLikeState.self)
            .do(onNext: { (state) in
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user?.profile?.update(with: state)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: state))
            })
            .map { _ in () }
        
    }
    
    func follow(shouldFollow: Bool, artistId: String) -> Maybe<Void> {
        
        ////TODO: apply optimistic policy
        return UserRequest.follow(artistId: artistId, shouldFollow: shouldFollow)
            .rx.response(type: ArtistFollowingState.self)
            .do(onNext: { (state) in
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user?.profile?.update(with: state)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: state))
            })
            .map { _ in () }
        
    }
    
}

extension Application {

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
