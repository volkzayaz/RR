//
//  WebSocketService.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Starscream
import Reachability
import RxSwift


typealias Signature = String

extension Signature {
    var isOwn: Bool {
        return self == WebSocketService.ownSignatureHash
    }
}

class WebSocketService {

    /////----------
    /////Interface
    /////----------
    
    var didReceivePlaylistPatch: Observable<TrackReduxViewPatch> {
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
    
    var didReceivePreviewTimes: Observable<[Int: UInt64]> {
        
        let channel = "previewOpt"
        let command = "srts_previews"
        
        return customCommandObservable(ofType: CodableWebSocketCommand<[Int: UInt64]>.self,
                                       channel: channel, command: command)
            .map { $0.data }
    }
    
    var didReceiveShuffle: Observable<ShouldShuffle> {
        return commandObservable()
    }
    
    var didReceiveRepeat: Observable<ShouldRepeat> {
        return commandObservable()
    }
    
    ////User mutations
    var didReceiveListeningSettings: Observable<ListeningSettings> {
        return commandObservable()
    }
    
    var didReceiveTrackForceToPlayState: Observable<TrackForceToPlayState> {
        return commandObservable()
    }
    
    var didReceiveArtistFollowingState: Observable<ArtistFollowingState> {
        return commandObservable()
    }
    
    var didReceiveSkipArtistAddonsState: Observable<SkipArtistAddonsState> {
        return commandObservable()
    }
    
    var didReceiveTrackLikeState: Observable<TrackLikeState> {
        return commandObservable()
    }
    
    /////----------
    /////Implementation
    /////----------
    
    ///some of the webSocket commands (trackState) are signed by each client
    ///our client will be signing commands with this hash
    static let ownSignatureHash: Signature = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    
    ///some commands are not signed by hash, but our logic rely on
    ///whether some particular command is created by our client, or alien client
    ///we will be using this hash to mark commands as alien
    ///note this hash will not be transported via webSocket to other clients
    static let alienSignatureHash: Signature = String(randomWithLength: 8, allowedCharacters: .alphaNumeric)
    
    private let webSocket: WebSocket
    private let reachability: Reachability
    private let tokenPipe = BehaviorSubject<Token?>(value: nil)
    private let bag = DisposeBag()
    
    func commandObservable<T: WSCommandData & Codable>() -> Observable<T> {
        return customCommandObservable(ofType: CodableWebSocketCommand<T>.self)
            .map { $0.data }
    }
    
    func customCommandObservable<T: WSCommand>(ofType: T.Type) -> Observable<T> where T.DataType: WSCommandData {
        return customCommandObservable(ofType: ofType,
                                       channel: T.DataType.channel,
                                       command: T.DataType.command)
    }
    
    func customCommandObservable<T: WSCommand>(ofType: T.Type, channel: String, command: String) -> Observable<T>  {

        return rxInput.filter { x in
            return x.channel == channel &&
                   x.command == command
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
    
    init() {
        webSocket = WebSocket(url: URL(string: "https://google.com")!)
        reachability = Reachability(hostname:"https://google.com")!
    }
    
    init(url: String) {
        
        guard let webSocketURL = URL(string: url) else {
            fatalError("Can't create websocket. Unsupported URL \(url)")
        }
        
        var r = URLRequest(url: webSocketURL)
        r.timeoutInterval = 1
        
        webSocket = WebSocket(request: r)
        reachability = Reachability(hostname: webSocketURL.host!)!
        
            try! self.reachability.startNotifier()
        
        Observable.combineLatest(reachability.rx.isReachable.distinctUntilChanged(),
                                 didDisconnect.startWith( () ),
                                 tokenPipe.asObservable().notNil().distinctUntilChanged())
            .flatMapLatest { [unowned self] (isReachable, disconnectTrigger, token) -> Observable<CodableWebSocketCommand<Token>> in
                
                print("\(isReachable)/\(disconnectTrigger)/\(token)")
                
                guard isReachable else { return Observable.never() }
                
                if self.webSocket.isConnected {
                    return .just(CodableWebSocketCommand(data: token))
                }
                
                self.webSocket.connect()
                
                return self.didConnect.take(1).map { _ in
                    return CodableWebSocketCommand(data: token)
                }
                
            }
            .subscribe(onNext: { (command: CodableWebSocketCommand<Token>) in
                self.sendCommand(command: command)
            })
            .disposed(by: bag)
        
    }

    func disconnect() {
        webSocket.disconnect()
    }

    //////Action with clear response
    
    func connect(with token: Token) {
        tokenPipe.onNext(token)
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

        sendCommand(command: CodableWebSocketCommand(data: trackIds,
                                                     channel: "playlist",
                                                     command: "getTracks"))
        
        return commandObservable().take(1)
        
    }
    
    ////normally we will receive organic updates via didReceivePreviewTimes
    ////but if for some reason we are not, feel free to poke webSokcet for the update
    func pokeForPreviewTime(for trackIds:[Int]) {
        
        let channel = "previewOpt"
        let command = "srts_previews"
        
        sendCommand(command: CodableWebSocketCommand(data: trackIds,
                                                     channel: channel,
                                                     command: command))
        
    }
    
    /////
    
    
    func sendCommand<T: WSCommand>(command: T) {
        
//        let str = String(bytes: command.jsonData, encoding: .utf8)
//        print("Sending out \(str)")
//
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
                
                print("Received message: \(text)")
                
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
