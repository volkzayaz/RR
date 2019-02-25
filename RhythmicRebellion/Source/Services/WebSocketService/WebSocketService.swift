//
//  WebSocketService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Starscream
import RxSwift

//protocol WebSocketServiceWatcher: class {
//
//    func webSocketServiceDidConnect(_ service: WebSocketService)
//    func webSocketServiceDidDisconnect(_ service: WebSocketService)
//
//    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings)
//    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState)
//    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState)
//    func webSocketService(_ service: WebSocketService, didReceivePurchases purchases: [Purchase])
//    func webSocketService(_ service: WebSocketService, didReceiveSkipArtistAddonsState skipArtistAddonsState: SkipArtistAddonsState)
//    func webSocketService(_ service: WebSocketService, didReceiveTrackLikeState trackLikeState: TrackLikeState)
//
//    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track], flush: Bool)
//    func webSocketService(_ service: WebSocketService, didReceivePlaylistUpdate playlistItemsPatches: [String: PlayerPlaylistItemPatch?], flush: Bool)
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?)
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState)
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool)
//    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons)
//    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool)
//
//    func webSocketService(_ service: WebSocketService, didRecieveFanPlaylistState fanPlaylistState: FanPlaylistState)
//
//    func didReceivePlaylist(patch: [String: [String: Any]?])
//}
//
//extension WebSocketServiceWatcher {
//
//    func webSocketServiceDidConnect(_ service: WebSocketService) { }
//    func webSocketServiceDidDisconnect(_ service: WebSocketService) { }
//
//    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings) { }
//    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState) { }
//    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState) { }
//    func webSocketService(_ service: WebSocketService, didReceivePurchases purchases: [Purchase]) { }
//    func webSocketService(_ service: WebSocketService, didReceiveSkipArtistAddonsState skipArtistAddonsState: SkipArtistAddonsState) { }
//    func webSocketService(_ service: WebSocketService, didReceiveTrackLikeState trackLikeState: TrackLikeState) { }
//
//    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track], flush: Bool) { }
//    func webSocketService(_ service: WebSocketService, didReceivePlaylistUpdate playlistItemsPatches: [String: PlayerPlaylistItemPatch?], flush: Bool) { }
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) { }
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) { }
//    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool) { }
//    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons) { }
//    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool) { }
//
//    func webSocketService(_ service: WebSocketService, didRecieveFanPlaylistState fanPlaylistState: FanPlaylistState) { }
//
//    func didReceivePlaylist(patch: [String: [String: Any]?]) {}
//}

class WebSocketService: WebSocketDelegate, Watchable {

    static let ownSignatureHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    
//    typealias WatchType = WebSocketServiceWatcher
//    let watchersContainer = WatchersContainer<WebSocketServiceWatcher>()
    
    var webSocket: WebSocket?
    var token: Token?

    fileprivate let r: URLRequest
    
    fileprivate lazy var rxInput: Observable<(data: Data, channel: String, command: String)> = {
       
        return Observable.create { (subscriber) -> Disposable in
            
            self.webSocket!.onText = { text in
                
                guard let data = text.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                      let cmd = json?["cmd"] as? String,
                      let channel = json?["channel"] as? String else {
                        return
                }
                
                subscriber.onNext( (data, channel, cmd) )
                
            }
            
            return Disposables.create {
                ///
            }
        }
        
    }()
    
    func commandObservable<T: WebSocketCommandCodable>() -> Observable<T> {

        return rxInput.filter { $0.channel == T.channel &&
                                $0.command == T.command }
            .map { x in
                
                let t: WebSocketCommand<T>
                do {
                    t = try JSONDecoder().decode(WebSocketCommand<T>.self, from: x.data)
                }
                catch (let e) {
                    fatalError("Error decoding \(T.self). Details: \(e)")
                }
                
                return t.data
            }
        
    }
    
    public init?(webSocketURI: String) {
        guard let webSocketURL = URL(string: webSocketURI) else { return nil }
        
        var r = URLRequest(url: webSocketURL)
        r.timeoutInterval = 1
        self.r = r
        
    }

    func makeWebSocket() -> WebSocket {
    
        let webSocket = WebSocket(request: r)
        webSocket.delegate = self
        
        return webSocket
    }

    func connect(with token: Token?, forceReconnect: Bool = false) {
        
        if let x = webSocket, x.isConnected, forceReconnect == false { return }
        
        guard let token = token else { return }
        
        self.token = token

        print("connect with Token: \(String(describing: self.token))")

        self.webSocket?.delegate = nil

        self.webSocket = self.makeWebSocket()
        self.webSocket?.connect()
        
        ////request -> response:
        ///1. Init = loadTracks + currentTrack + trackState
        ///2. Addons =
        
        rxInput.subscribe(onNext: { (txt) in
            print(txt)
        })
    }

    func reconnect() {
        connect(with: self.token)
    }

    func disconnect() {

        print("WebSocket disconnect!!!!")

        self.webSocket?.disconnect()
    }

    func sendCommand<T>(command: WebSocketCommand<T>, completion: ((Error?) -> ())? = nil) {

        guard self.webSocket?.isConnected == true else { completion?(AppError(WebSocketServiceError.offline)); return }

        do {
            let jsonData = try JSONEncoder().encode(command)

            self.webSocket?.write(data: jsonData, completion: { completion?(nil) })
        } catch (let error) {
            completion?(AppError(WebSocketServiceError.custom(error)))
        }
    }

    // MARK: - WebSocketDelegate -
    public func websocketDidConnect(socket: WebSocketClient) {

        if let token = self.token {
            let initialCommand = WebSocketCommand(data: token)
            self.sendCommand(command: initialCommand)
        }

    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect: \(String(describing: error))")

        self.webSocket?.delegate = nil
        self.webSocket = nil

//        let commandCenter = MPRemoteCommandCenter.shared()
//        commandCenter.nextTrackCommand.isEnabled = self.canForward
//        commandCenter.previousTrackCommand.isEnabled = self.canBackward
//
//        self.watchersContainer.invoke({ (observer) in
//            observer.player(player: self, didChange: .failed)
//        })
//
//        if self.audioSessionIsInterrupted == false && false { //self.webSocketService.isReachable {
//            self.webSocketService.reconnect()
//        }
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let data = text.data(using: .utf8) else { return }

        self.websocketDidReceiveData(socket: socket, data: data)
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {

        if let x = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any],
           let command = x["cmd"] as? String, command == "update",
           let channel = x["channel"] as? String, channel == "playlist",
           let d = x["data"] as? [String: [String: Any]?]   {
            watchersContainer.invoke { (x) in
                x.didReceivePlaylist(patch: d)
            }
        }
        
        
//        let webSoketCommand = try! JSONDecoder().decode(WebSocketCommand.self, from: data)
//
//        publishSubject.onNext(webSoketCommand.data)
//
//        switch webSoketCommand.data {
//
//        case .userInit( _ ):
//            break
//
//        case .userSyncListeningSettings(let listeningSettings):
//
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveListeningSettings: listeningSettings)
//            })
//
//        case .userSyncForceToPlay(let trackForceToPlayState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveTrackForceToPlayState: trackForceToPlayState)
//            })
//
//        case .userSyncFollowing(let artistFollowingState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveArtistFollowingState: artistFollowingState)
//            })
//
//        case .userSyncPurchases(let purchases):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceivePurchases: purchases)
//            })
//
//        case .userSyncSkipArtistAddons(let skipArtistAddonsState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveSkipArtistAddonsState: skipArtistAddonsState)
//            })
//
//        case .userSyncTrackLikeState(let trackLikeState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveTrackLikeState: trackLikeState)
//            })
//
//        case .playListLoadTracks(let tracks):
//
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveTracks: tracks, flush: webSoketCommand.flush ?? false)
//            })
//
//        case .playListUpdate(let playerPlaylistUpdate):
//
//            //                #if DEBUG
//            //                    print("recieve playListUpdate: \(String(data: data, encoding: .utf8))")
//            //                #endif
//
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceivePlaylistUpdate: playerPlaylistUpdate, flush: webSoketCommand.flush ?? false)
//            })
//
//        case .playListGetTracks( _): break
//
//        case .currentTrackId(let trackId):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveCurrentTrackId: trackId)
//            })
//
//        case .currentTrackState(let trackState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveCurrentTrackState: trackState)
//            })
//
//        case .currentTrackBlock(let isBlocked):
//
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveCurrentTrackBlock: isBlocked)
//            })
//
//        case .checkAddons(let checkAddons):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveCheckAddons: checkAddons)
//            })
//
//        case .playAddon( _): break
//
//        case .tracksTotalPlayTime(let tracksTotalPlayMSeconds):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didReceiveTracksTotalPlayTime: tracksTotalPlayMSeconds, flush: webSoketCommand.flush ?? false)
//            })
//
//        case .fanPlaylistsStates(let fanPlaylistState):
//            self.watchersContainer.invoke({ (observer) in
//                observer.webSocketService(self, didRecieveFanPlaylistState: fanPlaylistState)
//            })
//
//        case .failure(let error):
//            print(error)

        //}
    }
    
//    var didReceiveTracks: Single<[Track]> {
//        
//        return publishSubject.notNil()
//            .map { x -> [Track]? in
//                
//                guard case .playListLoadTracks(let tracks) = x else { return nil }
//                
//                return tracks
//            }
//            .notNil()
//            .take(1)
//            .asSingle()
//        
//    }
//    
//    var didReceiveAddons: Single<[Addon]> {
//        
//        return publishSubject.notNil()
//            .map { x -> [Addon]? in
//                
//                guard case .checkAddons(let checkAddons) = x else { return nil }
//                
//                return []
//            }
//            .notNil()
//            .take(1)
//            .asSingle()
//        
//    }
//    
}

