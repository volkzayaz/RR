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
        appState
            .distinctUntilChanged { $0.player.currentItem?.state == $1.player.currentItem?.state }
            .filter { $0.player.lastChangeSignatureHash.isOwn }
            .map { $0.player.currentItem?.state }
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: CodableWebSocketCommand(data: x))
                print("Sending out trackState for syncing with webSocket: \(x)")
                
            })
            .disposed(by: rx.disposeBag)
        
        ////sync current track ID
        appState
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .filter { $0.player.lastChangeSignatureHash.isOwn }
            .skip(1) ///initial nil
            .drive(onNext: { [weak w = webSocket] (state) in
                
                let t = TrackId(orderedTrack: state.currentTrack)
                
                let command = CodableWebSocketCommand(data: t)
                
                w?.sendCommand(command: command)
                print("Sending out currentTrackID for syncing with webSocket: \(String(describing: t))")
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState
            .distinctUntilChanged { $0.player.lastPatch == $1.player.lastPatch }
            .filter { $0.player.lastChangeSignatureHash.isOwn }
            .map { $0.player.lastPatch }
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: TrackReduxViewPatch(data: x.patch, shouldFlush: x.shouldFlush))
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                
            })
            .disposed(by: rx.disposeBag)
        
        /// sync blocked state
        webSocketAcceptableChange
            .distinctUntilChanged { $0.player.isBlocked == $1.player.isBlocked }
            .filter { $0.player.lastChangeSignatureHash.isOwn }
            .map { $0.player.isBlocked }
            .skip(1)///initial state
            .drive(onNext: { [weak w = webSocket] (x) in
                
                let data: TrackBlockState = x
                
                w?.sendCommand(command: CodableWebSocketCommand(data: data))
                
                print("Sending out block state via webSoccket isBlocked = \(x)")
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    func bindWebSocket() {
        
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
