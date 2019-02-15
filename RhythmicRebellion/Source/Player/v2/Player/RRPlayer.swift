//
//  RRPlayer.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

class RRPlayer: NSObject {
    
    let webSocket: WebSocketService
    let audioPlayer = AudioPlayer()
    
    init(webSocket: WebSocketService) {
        self.webSocket = webSocket
        
        super.init()
        
        webSocket.addWatcher(self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            webSocket.connect(with: Token(token: DataLayer.get.application.user!.wsToken,
                                          isGuest: DataLayer.get.application.user!.isGuest))
        }
        
        
        bind()
    }
}

////UI initiated
extension RRPlayer {

    func play() {
        
        ///TODO: investiate memmory leak upon play/pause cycles
        
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
        
    }
    
    func clear() {
        
    }
    
    enum AddStyle {
        case now, next, last
    }
    func add(tracks: [Track], type: AddStyle) {
        Dispatcher.dispatch(action: AddTracksToNowPlaying(tracks: tracks, style: type))
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

///web socket initiated
extension RRPlayer: WebSocketServiceWatcher {
    
    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track], flush: Bool) {
        
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        
        ////old code requested timeTracking request here
        
    }
    
    ////rewrite these 1 for async calls with immediate response
    
    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons) {
        
//        switch checkAddons.addons {
//        case .addonsIds(let addonsIds): self.apply(addonsIds: addonsIds)
//        default: break
//        }
    }
    
    //////
    
    func webSocketServiceDidConnect(_ service: WebSocketService) {
        ///in case didDisconnect change app state
        ///it should be equaled down in this method
    }
    
    func webSocketServiceDidDisconnect(_ service: WebSocketService) {
        
        ////not sure what to do with app state other than reconnect
        
        //webSocket.reconnect()
        
    }
    
    func didReceivePlaylist(patch: [String : [String : Any]?]) {
        let action = ApplyReduxViewPatch( viewPatch: .init(isOwn: false,
                                                           patch: patch.nullableReduxView) )
        
        Dispatcher.dispatch(action: action )
    }
    
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {
        
        guard let t = trackId else {
            return
        }
        
        Dispatcher.dispatch(action: PrepareNewTrackByHash(orderHash: t.key))
        
    }
    
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {
        Dispatcher.dispatch(action: ChangeTrackState(trackState: trackState))
    }
    
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool) {
        
        ////update appState with blocked
        
    }
    
    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool) {
        
        ////update app state with new playback seconds
        
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
            .drive(onNext: { (x) in
                
                print("Sending out trackState for syncing with webSocket: \(x)")
                
                ///self.webSocket.sendCommand(command: WebSocketCommand.setTrackState(trackState: x))
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState.map { $0.player.lastPatch }
            .distinctUntilChanged()
            .notNil()
            .filter { $0.isOwn }
            .filter { _ in true } ///TODO: here odd logic with filtering out masterSendDate should be present
                                  ///////some cool logic about skipping such requests
                                  ///guard Date().timeIntervalSince(self.isMasterStateSendDate) > 1.0 else { /*print("BadTime");*/ return }
                                  ////take into account Hash of this state
            .drive(onNext: { (x) in
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                //self.webSocket.sendCommand(command: WebSocketCommand.updatePlaylist(playlistItemsPatches: [String : PlayerPlaylistItemPatch?]))
                
            })
            .disposed(by: rx.disposeBag)
        
        ////sync current track ID
        appState.map { $0 }
            .distinctUntilChanged { $0.player == $1.player }
        /// TODO: we should not send out commands for actions that are not our own
        ///.filter { $0.isOwn }
            .drive(onNext: { (state) in

                guard let orderedTrack = state.currentTrack else {
                    return
                }
                
                let t = TrackId(id: orderedTrack.track.id, key: orderedTrack.orderHash)
                
                print("Sending out currentTrackID for syncing with webSocket: \(t)")
                //self.webSocket.sendCommand(command: .setCurrentTrack(trackId: TrackId(id: id, key: hash)))
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

struct ProceedToNextItem: ActionCreator {
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        guard var currentItem = initialState.player.currentItem else {
            return .just(initialState)
        }
        
        var state = initialState
        
        if currentItem.addons.count > 0 {
            var addons = currentItem.addons
            let next = addons.removeFirst()
            
            currentItem.addons = addons
            currentItem.musicType = .addon(next)
            
            state.player.currentItem = currentItem
            
            return .just(state)
        }
        else if let next = state.nextTrack {
            return PrepareNewTrack(orderedTrack: next,
                                   shouldPlayImmidiatelly: true).perform(initialState: state)
        }

        return .just(state)
    }
    
}

struct PrepareNewTrackByHash: ActionCreator {
    
    let orderHash: TrackOrderHash
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        guard let x = initialState.player.tracks[orderHash] else {
            fatalErrorInDebug(" Can't start playing track with order key: \(orderHash). It is not found in reduxView: \(initialState.player.tracks) ")
            return .just(initialState)
        }
        
        return PrepareNewTrack(orderedTrack: x,
                               shouldPlayImmidiatelly: false).perform(initialState: initialState)
    }
    
}

struct PrepareNewTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    let shouldPlayImmidiatelly: Bool
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        ///TODO: request addons and verify them
        ///1. check addons
        ///2. start playing addons if any
        ///3. start music playback
        
        var state = initialState
        
        state.player.currentItem = DaPlayerState.CurrentItem(activeTrackHash: orderedTrack.orderHash,
                                                             addons: [],
                                                             musicType: .track(orderedTrack.track),
                                                             state: .init(hash: WebSocketService.ownSignatureHash,
                                                                          progress: 0,
                                                                          isPlaying: shouldPlayImmidiatelly))
        
        return .just(state)
        
    }
    
}

struct StoreTracks: Action {
    
    let tracks: [Track]
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        
        tracks.forEach { state.player.tracks.trackDump[$0.id] = $0 }
        
        return state
    }
    
}

struct ScrubToFraction: Action {
    
    let fraction: Float
    
    func perform(initialState: AppState) -> AppState {
        
        guard let secs = initialState.currentTrack?.track.audioFile?.duration else {
            return initialState
        }

        var state = initialState
        
        state.player.currentItem?.state.progress = TimeInterval(secs) * Double(fraction)
        
        return state
    }
    
}

struct ChangeTrackState: Action {
    
    let trackState: TrackState
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        state.player.currentItem?.state = trackState
        return state
    }
    
}

struct AddTracksToNowPlaying: ActionCreator {
    
    let tracks: [Track]
    let style: RRPlayer.AddStyle
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        switch style {
        case .next:
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
            
        case .now:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
                .flatMap { newState in
                    
                    guard let newCurrentTrack = newState.nextTrack ?? newState.firstTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: newCurrentTrack,
                                           shouldPlayImmidiatelly: true).perform(initialState: newState)
                }
            
        case .last:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.player.tracks.orderedTracks.last, isOwnChange: true)
                .perform(initialState: initialState)
            
        }
        
        
    }
    
}

struct RemoveTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        var maybeNextTrack: OrderedTrack? = nil
        if initialState.currentTrack == orderedTrack {
            maybeNextTrack = initialState.nextTrack ?? initialState.firstTrack
        }
        
        return DeleteTrack(track: orderedTrack, isOwnChange: true)
                .perform(initialState: initialState)
                .flatMap { newState in
                    
                    guard let c = maybeNextTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: c,
                                           shouldPlayImmidiatelly: initialState.player.currentItem?.state.isPlaying ?? false)
                        .perform(initialState: newState)
                    
                }
        
    }
    
}
