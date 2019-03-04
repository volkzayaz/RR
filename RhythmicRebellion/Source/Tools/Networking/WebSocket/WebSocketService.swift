//
//  WebSocketService.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Starscream
import RxSwift

extension WebSocketService {
    
    var didReceivePlaylistPatch: Observable<TrackReduxViewPatch> {
        return customCommandObservable(ofType: TrackReduxViewPatch.self)
    }
    
    var didReceiveTracks: Observable<[Track]> {
        return commandObservable()
    }
    
    var didReceiveTrackState: Observable<TrackState> {
        return commandObservable()
            .filter { _ in WebSocketService.masterDate.timeIntervalSinceNow < -0.4 }
    }
    
    var didReceiveCurrentTrack: Observable<TrackId?> {
        return commandObservable().map { (maybeTrack: TrackId?) in
            if let x = maybeTrack, x.id == 0 {
                ///socket returns {"id": 0, "key": ""}} instead of null for no track
                return nil
            }
            
            return maybeTrack
        }
    }
    
    var didReceiveTrackBlockState: Observable<TrackBlockState> {
        return commandObservable()
    }
    
    //var did
    
}

class WebSocketService {

    ///some of the webSocket commands (trackState) are signed by each client
    ///our client will be signing commands with this hash
    static let ownSignatureHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    
    ///some commands are not signed by hash, but our logic rely on
    ///whether some particular command is created by our client, or alien client
    ///we will be using this hash to mark commands as alien
    ///not this hash will not be transported via webSocket to other clients
    static let alienSignatureHash = String(randomWithLength: 8, allowedCharacters: .alphaNumeric)
    
    ///Piece of data needed by WebSocket protocol
    ///Whenever you send out a setTrackState commad, you become a master client
    ///The rest become slave clients
    ///The rule is: If you've just became master, you must ignore all "currentTrack" and "trackState" commands
    ///for the next 1 second ¯\_(ツ)_/¯
    static var masterDate = Date(timeIntervalSince1970: 0)
    
    let webSocket: WebSocket
    
    func commandObservable<T: WSCommandData & Codable>() -> Observable<T> {
        return customCommandObservable(ofType: CodableWebSocketCommand<T>.self)
            .map { $0.data }
    }
    
    func customCommandObservable<T: WSCommand>(ofType: T.Type) -> Observable<T> {

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
                
                return t
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
    
    func connect(with token: Token) {
        
        if webSocket.isConnected {
            self.sendCommand(command: CodableWebSocketCommand(data: token))
            return
        }
        
        webSocket.connect()
        
        let _ = didConnect.take(1).subscribe(onNext: { [unowned self] _ in
              self.sendCommand(command: CodableWebSocketCommand(data: token))
        })
        
    }
    
    func filter(addons: [Addon], for track: Track) -> Observable<[Addon]> {
        
        //return .just(addons)
        
        guard addons.count > 0 else {
            return .just(addons)
        }
        
        let x = CheckAddons<AddonState>(trackID: track.id,
                                        representation: addons.map { AddonState(trackId: track.id, addon: $0) })
        
        sendCommand(command: CodableWebSocketCommand(data: x) )
        
        let response: Observable<CheckAddons<Int>> = commandObservable()
        
        return response.map { res in
            
            let filteredAddons = addons.filter { res.addonRepresentation.contains($0.id) }
        
            let addonsTypesWeight: [Addon.AddonType] = [.advertisement, .artistBIO, .songCommentary, .artistAnnouncements, .songIntroduction]
            
            return filteredAddons.sorted(by: { (firstAddon, secondAddon) -> Bool in
                guard let firstAddonTypeWeight = addonsTypesWeight.index(of: firstAddon.type) else { return false }
                guard let secondAddonTypeWeight = addonsTypesWeight.index(of: secondAddon.type) else { return true }
                
                return firstAddonTypeWeight <= secondAddonTypeWeight
            })
            
        }
        .take(1)
        
    }
    
    func markPlayed(addon: Addon, for track: Track) {
        //return;
        sendCommand(command: CodableWebSocketCommand(data: AddonState(trackId: track.id,
                                                                      addon: addon))  )
    }
    
    func fetchTracks(trackIds: [Int]) -> Observable<[Track]> {
        
        sendCommand(command: CodableWebSocketCommand(data: trackIds))
        
        return commandObservable().take(1)
        
    }
    
    /////
    
    
    func sendCommand<T: WSCommand>(command: T) {
        
        ///take a look at masterDate definition for more explanation
        if command.data is TrackState {
            WebSocketService.masterDate = Date()
        }
        
        webSocket.write(data: command.jsonData, completion: {
            
        })
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
