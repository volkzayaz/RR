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

class RRPlayer: Actor {
    
    var webSocket: WebSocketService {
        return DataLayer.get.webSocketService
    }
    
    init() {
        connect()
        bind()
        bindWebSocket()
    }
    
    ///Piece of data needed by WebSocket protocol
    ///Whenever you send out a setTrackState commad, you become a master client
    ///The rest become slave clients
    ///The rule is: If you've just became master, you must ignore all "currentTrack" and "trackState" commands
    ///for the next 1 second ¯\_(ツ)_/¯
    fileprivate let masterDate = BehaviorSubject(value: Date())
    
    fileprivate let bag = DisposeBag()
}

////UI initiated
extension RRPlayer {
    
    func add(tracks: [Track], type: AddTracksToLinkedPlaying.AddStyle) {
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: type))
    }
    
}

///Push state into webSocket
extension RRPlayer {
    
    func connect() {
        
        appState.map { $0.user }
            .map {
                Token(token: $0.wsToken, isGuest: $0.isGuest)
            }
            .distinctUntilChanged()
            .drive(onNext: { [weak ws = webSocket] (token) in
                ws?.connect(with: token)
            })
            .disposed(by: bag)
        
    }
    
    func bind() {

        /////-----
        ////Syncing using webSocket
        /////-----
        
        /// sync player state
        appState.ownChangesOnlyOf { $0.player.currentItem?.state }
            .map { $0.player.currentItem?.state }
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: CodableWebSocketCommand(data: x))
                print("Sending out trackState for syncing with webSocket: \(x)")
                
            })
            .disposed(by: bag)
        
        ////sync current track ID
        appState.ownChangesOnlyOf { $0.currentTrack }
            .skip(1) ///initial nil
            .drive(onNext: { [weak w = webSocket] (state) in
                
                let t = TrackId(orderedTrack: state.currentTrack)
                
                let command = CodableWebSocketCommand(data: t)
                
                w?.sendCommand(command: command)
                print("Sending out currentTrackID for syncing with webSocket: \(String(describing: t))")
            })
            .disposed(by: bag)
        
        /// sync playlist order (insert/delete/create/flush)
        appState.ownChangesOnlyOf { $0.player.lastPatch }
            .map { $0.player.lastPatch }
            .notNil()
            .drive(onNext: { [weak w = webSocket] (x) in
                
                w?.sendCommand(command: TrackReduxViewPatch(data: x.patch, shouldFlush: x.shouldFlush))
                
                print("Sending out patch for syncing with webSocket: \(x.patch)")
                
            })
            .disposed(by: bag)
        
        /// sync blocked state
        appState.ownChangesOnlyOf { $0.player.isBlocked }
            .map { $0.player.isBlocked }
            .skip(1)///initial state
            .drive(onNext: { [weak w = webSocket] (x) in
                
                let data: TrackBlockState = x
                
                w?.sendCommand(command: CodableWebSocketCommand(data: data))
                
                print("Sending out block state via webSoccket isBlocked = \(x)")
                
            })
            .disposed(by: bag)
        
        ////sync master date
        appState.ownChangesOnlyOf { $0.player.lastChangeSignatureHash }
            .distinctUntilChanged { $0.player.currentItem?.state == $1.player.currentItem?.state }
            .map { _ in Date() }
            .drive(masterDate)
            .disposed(by: bag)
        
    }
    
    func bindWebSocket() {
        
        webSocket.didReceivePlaylistPatch
            .subscribe(onNext: { (patch) in
                let action = ApplyReduxViewPatch( viewPatch: .init(shouldFlush: patch.shouldFlush,
                                                                   patch: patch.data) )
                
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: action) )
            })
            .disposed(by: bag)
        
        webSocket.didReceiveTracks
            .subscribe(onNext: { (tracks) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: StoreTracks(tracks: tracks)) )
            })
            .disposed(by: bag)
        
        webSocket.didReceiveCurrentTrack
            .subscribe(onNext: { (t) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: PrepareNewTrackByHash(orderHash: t?.key)))
            })
            .disposed(by: bag)
        
        webSocket.didReceiveTrackState
            .filter { _ in self.masterDate.unsafeValue.timeIntervalSinceNow < -0.4 }
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: ChangeTrackState(trackState: state)))
            })
            .disposed(by: bag)

        webSocket.didReceiveTrackBlockState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: ChangePlayerBlockState(isBlocked: state)))
            })
            .disposed(by: bag)
        
        webSocket.didReceivePreviewTimes
            .subscribe(onNext: { (times) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateTrackPrviewTimes(newPreviewTimes: times)))
            })
            .disposed(by: bag)
        
        ////User mutations
        
        webSocket.didReceiveListeningSettings
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateUser { user in
                    user.profile?.listeningSettings = state
                }))
            })
            .disposed(by: bag)
        
        webSocket.didReceiveTrackForceToPlayState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateUser { user in
                    user.profile?.update(with: state)
                }))
            })
            .disposed(by: bag)
        
        webSocket.didReceiveArtistFollowingState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateUser { user in
                    user.profile?.update(with: state)
                }))
            })
            .disposed(by: bag)
        
        webSocket.didReceiveSkipArtistAddonsState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateUser { user in
                    user.profile?.update(with: state)
                }))
            })
            .disposed(by: bag)
        
        webSocket.didReceiveTrackLikeState
            .subscribe(onNext: { (state) in
                Dispatcher.dispatch(action: AlienSignatureWrapper(action: UpdateUser { user in
                    user.profile?.update(with: state)
                }))
            })
            .disposed(by: bag)
        
        
        
            //    func webSocketService(_ service: WebSocketService, didReceivePurchases purchases: [Purchase]) {
            //        guard let currentFanUser = self.user as? User else { return }
            //
            //        var fanUser = currentFanUser
            //        fanUser.profile?.update(with: purchases)
            //        self.user = fanUser
            //
            //        notifyUserProfileChanged(purchasedTracksIds: fanUser.profile?.purchasedTracksIds,
            //                                 previousPurchasedTracksIds: currentFanUser.profile.purchasedTracksIds)
            //    }
            //
            //    func webSocketService(_ service: WebSocketService, didRecieveFanPlaylistState fanPlaylistState: FanPlaylistState) {
            //        guard (self.user as? User) != nil else { return }
            //
            //        notifyFanPlaylistChanged(with: fanPlaylistState)
            //    }
            //
        
    }
    
}

import RxCocoa
extension Driver where E == AppState {
    
    func ownChangesOnlyOf<T: Equatable>( mapper: @escaping (AppState) -> T) -> SharedSequence {
        
        return distinctUntilChanged({ (lhs, rhs) -> Bool in
                return mapper(lhs) == mapper(rhs)
            })
            .filter { $0.player.lastChangeSignatureHash.isOwn }
        
    }
    
}
