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
    
}

class WebSocketService {

    static let ownSignatureHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    
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
    
    public init?(webSocketURI: String) {
        guard let webSocketURL = URL(string: webSocketURI) else { return nil }
        
        var r = URLRequest(url: webSocketURL)
        r.timeoutInterval = 1
        self.r = r
        
    }

    func makeWebSocket() -> WebSocket {
    
        let webSocket = WebSocket(request: r)
        
        return webSocket
    }

    func connect(with token: Token?, forceReconnect: Bool = false) {
        
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

    func reconnect() {
        connect(with: self.token)
    }

    func disconnect() {

        print("WebSocket disconnect!!!!")

        self.webSocket?.disconnect()
    }

    func sendCommand<T: WSCommand>(command: T, completion: ((Error?) -> ())? = nil) {

        guard self.webSocket?.isConnected == true else { completion?(AppError(WebSocketServiceError.offline)); return }

        let jsonData = command.jsonData
        
        self.webSocket?.write(data: jsonData)
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

}

