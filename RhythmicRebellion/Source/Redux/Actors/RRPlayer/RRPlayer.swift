//
//  RRPlayer.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

/******
 *  All the rules about syncing player state between clients live in this actor
 */

///TODO: drop NSObject conformance once Application is reactified
class RRPlayer: NSObject {
    
    let webSocket: WebSocketService
    let audioPlayer = AudioPlayer()
    let mediaWidget = MediaWidget()
    
    init(application: Application) {
        self.webSocket = application.webSocketService
        
        super.init()
        
        bind()
        bindWebSocket()
        
        application.addWatcher(self)
    }
    
}

///TODO: migrate to proper reactive callbacks
///User changes
extension RRPlayer : ApplicationWatcher {

    func application(_ application: Application, didChangeUserToken user: User) {
        webSocket.connect(with: Token(token: user.wsToken,
                                      isGuest: user.isGuest))
        
    }
    
    func application(_ application: Application, didChange user: User) {
        webSocket.connect(with: Token(token: user.wsToken,
                                      isGuest: user.isGuest))
    }
    
}

////UI initiated
extension RRPlayer {

    func play() {
        Dispatcher.dispatch(action: AudioPlayer.Play())
    }
    
    func pause() {
        Dispatcher.dispatch(action: AudioPlayer.Pause())
    }
    
    func flip() {
        Dispatcher.dispatch(action: AudioPlayer.Switch())
    }
 
    func skipForward() {
        Dispatcher.dispatch(action: ProceedToNextItem())
    }
    
    func skipBack() {
        Dispatcher.dispatch(action: GetBackToPreviousItem())
    }
    
    func clear() {
        Dispatcher.dispatch(action: ClearTracks())
    }
    
    enum AddStyle {
        case now, next, last
    }
    func add(tracks: [Track], type: AddStyle) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: type))
    }
    
    func remove(track: OrderedTrack) {
        Dispatcher.dispatch(action: RemoveTrack(orderedTrack: track))
    }
    
    func seek(to fraction: Float) {
        Dispatcher.dispatch(action: ScrubToFraction(fraction: fraction))
    }
    
    func `switch`(to track: OrderedTrack) {
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: track, shouldPlayImmidiatelly: true))
    }
    
}

///Push state into webSocket
extension RRPlayer {
    
    func bind() {

        /////-----
        ////Syncing using webSocket
        /////-----
        
        let webSocketAcceptableChange = appState.filter { $0.player.lastChangeSignatureHash.isOwn }
        
        /// sync player state
        webSocketAcceptableChange.map { $0.player.currentItem?.state }
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: CodableWebSocketCommand(data: x))
                print("Sending out trackState for syncing with webSocket: \(x)")
                
            })
            .disposed(by: rx.disposeBag)
        
        ////sync current track ID
        webSocketAcceptableChange.map { $0 }
            .skip(1) ///initial nil
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .drive(onNext: { [weak w = webSocket] (state) in
                
                let t = TrackId(orderedTrack: state.currentTrack)
                
                let command = CodableWebSocketCommand(data: t)
                
                w?.sendCommand(command: command)
                print("Sending out currentTrackID for syncing with webSocket: \(String(describing: t))")
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        webSocketAcceptableChange.map { $0.player.lastPatch }
            .distinctUntilChanged()
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: TrackReduxViewPatch(data: x.patch, shouldFlush: x.shouldFlush))
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                
            })
            .disposed(by: rx.disposeBag)
        
        /// sync blocked state
        webSocketAcceptableChange.map { $0.player.isBlocked }
            .distinctUntilChanged()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                let data: TrackBlockState = x
                
                w?.sendCommand(command: CodableWebSocketCommand(data: data))
                
                print("Sending out block state via webSoccket isBlocked = \(x)")
                
            })
            .disposed(by: rx.disposeBag)
        
        
        ////apply RR specific logic
        
        ////Enforce playback termination if user exceeded play time quota
        appState.map { $0.player }
            //.filter { $0.state.isOwn }
            .drive(onNext: { (x) in
                
                //print("Checking restricted time \(x)")
                
                ///Dispatcher.dispatch(action: CheckRestrictedTime(newState: x))
            })
            .disposed(by: rx.disposeBag)
        
        
    }
    
    func bindWebSocket() {
        
//        webSocket.didConnect
//            .subscribe(onNext: {
//                print("DidConnect")
//            })
//        
//        webSocket.didDisconnect
//            .subscribe(onNext: {
//                print("DidDisconnect")
//            })
        
        webSocket.didReceivePlaylistPatch
            .subscribe(onNext: { (patch) in
                let action = ApplyReduxViewPatch( viewPatch: .init(shouldFlush: patch.shouldFlush,
                                                                   patch: patch.data) )
                
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: action) )
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTracks
            .subscribe(onNext: { (tracks) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: StoreTracks(tracks: tracks)) )
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveCurrentTrack
            .subscribe(onNext: { (t) in

                Dispatcher.dispatch(action: AlienSignatureWrapper(action: PrepareNewTrackByHash(orderHash: t?.key)))
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTrackState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: ChangeTrackState(trackState: state)))
            })
            .disposed(by: rx.disposeBag)

        webSocket.didReceiveTrackBlockState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: ChangePlayerBlockState(isBlocked: state)))
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceivePreviewTimes
            .subscribe(onNext: { (times) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateTrackPrviewTimes(newPreviewTimes: times)))
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}



///////

struct CheckRestrictedTime: Action {
    
    //let newState: DaPlayerState.PlayingNow
    
    func perform(initialState: AppState) -> AppState {
        
//        guard case .track(let x)? = newState.musicType,
//              let allowedTime = initialState.allowedTimes[x.id],
//              allowedTime <= UInt(newState.state.progress) else {
//        
//            return initialState
//        }
//        
        fatalError("advance to next song, since we ellapsed listening time")
        
    }
}
