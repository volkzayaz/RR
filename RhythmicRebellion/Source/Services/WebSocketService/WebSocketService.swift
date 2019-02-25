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

extension WebSocketService {
    
    var didReceivePlaylistPatch: Observable<DaPlaylist.NullableReduxView> {
        return customCommandObservable(ofType: TrackReduxViewPatch.self)
    }
    
    var didReceiveTracks: Observable<[Track]> {
        return commandObservable()
    }
    
    var didReceiveTrackState: Observable<TrackState> {
        return commandObservable()
    }
    
    var didReceiveCurrentTrack: Observable<TrackId?> {
        return commandObservable()
    }
    
}

class WebSocketService {

    static let ownSignatureHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    
    let webSocket: WebSocket
    
    func commandObservable<T: WSCommandData & Codable>() -> Observable<T> {
        return customCommandObservable(ofType: CodableWebSocketCommand<T>.self)
    }
    
    func customCommandObservable<T: WSCommand>(ofType: T.Type) -> Observable<T.DataType> {

        return rxInput.filter { $0.channel == T.DataType.channel &&
                                $0.command == T.DataType.command }
            .map { x in
                
                let t: T
                do {
                    t = try T(jsonData: x.data)
                }
                catch (let e) {
                    fatalError("Error decoding \(T.self). Details: \(e)")
                }
                
                return t.data
            }
        
    }
    
    init(url: String) {
        guard let webSocketURL = URL(string: url) else {
            fatalError("Can't create websocket. Unsupported URL \(url)")
        }
        
        var r = URLRequest(url: webSocketURL)
        r.timeoutInterval = 1
        
        self.webSocket = WebSocket(request: r)
    }

    func disconnect() {
        webSocket.disconnect()
    }

    
    
    
    
    func connect(with token: Token?, forceReconnect: Bool = false) -> Single<([Track], TrackState, TrackId)> {
        
        let res = didConnect.take(1).flatMap { _ in
            
        }
        
        if let x = webSocket, x.isConnected, forceReconnect == false { return }
        
        guard let token = token else { return }
        
        self.token = token
        
        print("connect with Token: \(String(describing: self.token))")
        
        self.webSocket = self.makeWebSocket()
        self.webSocket?.connect()
        
        ////request -> response:
        ///1. Init = loadTracks + currentTrack + trackState
        ///2. Addons =
        
        rxInput.subscribe(onNext: { (txt) in
            print(txt)
        })
    }
    
    
    
    
    
    func sendCommand<T: WSCommand>(command: T) {
        webSocket.write(data: command.jsonData)
    }

    // MARK: - WebSocketDelegate -
    public func websocketDidConnect(socket: WebSocketClient) {

        if let token = self.token {
            let initialCommand = CodableWebSocketCommand(data: token)
            self.sendCommand(command: initialCommand)
        }

    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect: \(String(describing: error))")

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

    fileprivate lazy var rxInput: Observable<(data: Data, channel: String, command: String)> = {
        
        return Observable.create { [unowned w = self.webSocket] (subscriber) -> Disposable in
            
            w.onText = { text in
                
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
            .share()
        
    }()
    
    lazy var didConnect: Observable<Void> = {
        
        return Observable.create { [unowned w = self.webSocket] (subscriber) -> Disposable in
            
            w.onConnect = {
                subscriber.onNext( () )
            }
            
            return Disposables.create {
                ///
            }
        }
        .share()
        
    }()
    
    lazy var didDisconnect: Observable<Void> = {
        
        return Observable.create { [unowned w = self.webSocket] (subscriber) -> Disposable in
            
            w.onDisconnect = { _ in
                subscriber.onNext( () )
            }
            
            return Disposables.create {
                ///
            }
        }
        .share()
        
    }()
    
}
