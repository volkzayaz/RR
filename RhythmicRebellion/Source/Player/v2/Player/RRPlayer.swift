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
    
    let webSocket = RouterDependencies.get.webSocketService
    
    override init() {
        super.init()
        
        webSocket.addWatcher(self)
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
        
    }
    
    func remove(track: OrderedTrack) {
        
    }
    
    func seek(to time: TimeInterval) {
        
    }
    
    func `switch`(to track: OrderedTrack) {
        
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
        
        webSocket.reconnect()
        
    }
    
    func webSocketService(_ service: WebSocketService, didReceivePlaylistUpdate playlistItemsPatches: [String: PlayerPlaylistItemPatch?], flush: Bool) {
        
        let action = ApplyReduxViewPatch( viewPatch: .init(isOwn: false,
                                                           patch: playlistItemsPatches.nullableReduxView) )
        
        Dispatcher.dispatch(action: action )

    }
    
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {
        
        ////change currentPlaying item in AppState
        
    }
    
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {
        
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
        appState.map { $0.player.playingNow.state }
            .filter { $0.isOwn }
            .drive(onNext: { (x) in
                
                print("Sending out trackState for syncing with webSocket: \(x)")
                
                ///self.webSocket.sendCommand(command: WebSocketCommand.setTrackState(trackState: x))
            })
            .disposed(by: rx.disposeBag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState.map { $0.player.playlist.lastPatch }
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
        appState.map { $0.player.playlist }
            .distinctUntilChanged()
        /// TODO: we should not send out commands for actions that are not our own
        ///.filter { $0.isOwn }
            .drive(onNext: { (playlist) in

                guard let hash = playlist.activeTrackHash,
                      let id = playlist.tracks[hash]?.track.id else {
                    return
                }
                
                let t = TrackId(id: id, key: hash)
                
                print("Sending out currentTrackID for syncing with webSocket: \(t)")
                //self.webSocket.sendCommand(command: .setCurrentTrack(trackId: TrackId(id: id, key: hash)))
            })
            .disposed(by: rx.disposeBag)
        
        
        
        ////apply RR specific logic
        
        ////Enforce playback termination if user exceeded play time quota
        appState.map { $0.player.playingNow }
            .filter { $0.state.isOwn }
            .drive(onNext: { (x) in
                
                print("Checking restricted time \(x)")
                
                ///Dispatcher.dispatch(action: CheckRestrictedTime(newState: x))
            })
            .disposed(by: rx.disposeBag)

        ////dequeue next playable item upon change in current playback item
        appState.map { $0.player.playlist }
            .distinctUntilChanged { $0.activeTrackHash == $1.activeTrackHash }
            .drive(onNext: { (playlist) in
                
                guard let hash = playlist.activeTrackHash,
                      let orderedTrack = playlist.tracks[hash] else { return }
                
                Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack))
                
            })
            .disposed(by: rx.disposeBag)
        
        
    }
    
}



///////

struct CheckRestrictedTime: Action {
    
    let newState: DaPlayerState.PlayingNow
    
    func perform(initialState: AppState) -> AppState {
        
        guard case .track(let x)? = newState.musicType,
              let allowedTime = initialState.allowedTimes[x.id],
              allowedTime <= UInt(newState.state.progress) else {
        
            return initialState
        }
        
        fatalError("advance to next song, since we ellapsed listening time")
        
    }
}

struct ProceedToNextItem: Action {
    
    func perform(initialState: AppState) -> AppState {
        
        guard let activeTrack = initialState.player.playlist.activeTrackHash else {
            return initialState
        }
        
        var state = initialState
        
        if state.player.playlist.addons.count > 0 {
            var addons = state.player.playlist.addons
            let next = addons.removeFirst()
            
            state.player.playlist.addons = addons
            state.player.playingNow.musicType = .addon(next)
        }
        else if let next = state.player.playlist.tracks.next(after: activeTrack) {
            state.player.playlist.activeTrackHash = next.orderHash
        }

        return state
    }
    
}

struct PrepareNewTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    
    func perform(initialState: AppState) -> Single<AppState> {
        
        ///TODO: request addons and verify them
        ///1. check addons
        ///2. start playing addons if any
        ///3. start music playback
        
        var state = initialState
        state.player.playingNow.musicType = .track(orderedTrack.track)
        
        return .just(state)
        
    }
    
}

struct StoreTracks: Action {
    
    let tracks: [Track]
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        
        tracks.forEach { state.player.playlist.tracks.trackDump[$0.id] = $0 }
        
        return state
    }
    
}
