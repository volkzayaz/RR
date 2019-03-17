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
    
    ////TODO: awful hack. Works for the case:
    ////To sync appState's currentItem we usually user currentItem.state.isOwn hash
    ////we only send out currentItems, that are signed with our own hash
    ////however in case currentItem is nil (which is also needs syncing if was created by us)
    ////we have no way of knowing if currentItem = nil is produced by our client or alien client
    ////hence this hacky bool
    private var shouldSkipSingleNilInCurrentItem: Bool = false
    
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
        
        /// sync player state
        appState.map { $0.player.currentItem?.state }
            .notNil()
            .filter { $0.isOwn }
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: CodableWebSocketCommand(data: x))
                print("Sending out trackState for syncing with webSocket: \(x)")
                
            })
            .disposed(by: rx.disposeBag)
        
        ////sync current track ID
        appState.map { $0 }
            .distinctUntilChanged { $0.currentTrack == $1.currentTrack }
            .skip(1)
            .drive(onNext: { [weak w = webSocket, weak self] (state) in

                if let x = state.player.currentItem, !x.state.isOwn { return }
                if self?.shouldSkipSingleNilInCurrentItem ?? false {
                    self?.shouldSkipSingleNilInCurrentItem = false
                    return
                }
                
                let t = TrackId(orderedTrack: state.currentTrack)
                
                let command = CodableWebSocketCommand(data: t)
                
                w?.sendCommand(command: command)
                print("Sending out currentTrackID for syncing with webSocket: \(String(describing: t))")
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState.map { $0.player.lastPatch }
            .distinctUntilChanged()
            .notNil()
            .filter { $0.isOwn }
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: TrackReduxViewPatch(data: x.patch, shouldFlush: x.shouldFlush))
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                
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
                let action = ApplyReduxViewPatch( viewPatch: .init(isOwn: false,
                                                                   shouldFlush: patch.shouldFlush,
                                                                   patch: patch.data) )
                
                Dispatcher.dispatch(action: action )
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTracks
            .subscribe(onNext: { (tracks) in
                Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveCurrentTrack
            .subscribe(onNext: { [weak self] (t) in
                
                self?.shouldSkipSingleNilInCurrentItem = true
                
                Dispatcher.dispatch(action: PrepareNewTrackByHash(orderHash: t?.key))
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceiveTrackState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: ChangeTrackState(trackState: state))
            })
            .disposed(by: rx.disposeBag)

        webSocket.didReceiveTrackBlockState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: ChangePlayerBlockState(isBlocked: state))
            })
            .disposed(by: rx.disposeBag)
        
        webSocket.didReceivePreviewTimes
            .subscribe(onNext: { (times) in
                Dispatcher.dispatch(action: UpdateTrackPrviewTimes(newPreviewTimes: times)) 
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
