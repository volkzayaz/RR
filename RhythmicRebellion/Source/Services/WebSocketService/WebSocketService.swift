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
    
    var didReceiveTrackBlockState: Observable<TrackBlockState> {
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

        return rxInput.filter { x in
            return x.channel == T.DataType.channel &&
                   x.command == T.DataType.command
            }
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

    
    
    //////Action with clear response
    
    func connect(with token: Token, forceReconnect: Bool = false) {
        
        webSocket.connect()
        
        let _ = didConnect.take(1).subscribe(onNext: { [unowned self] _ in
              self.sendCommand(command: CodableWebSocketCommand(data: token))
        })
        
    }
    
    
    func sendCommand<T: WSCommand>(command: T) {
        webSocket.write(data: command.jsonData)
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
