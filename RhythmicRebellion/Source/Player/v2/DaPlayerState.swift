//
//  PlayerState.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

private let _appState: BehaviorRelay<AppState> = {
    
    let x = AppState(player: DaPlayerState(playlist: DaPlayerState.Playlist(tracks: DaPlaylist(),
                                                                            lastPatch: nil,
                                                                            addons: [],
                                                                            activeTrackHash: nil),
                                           playingNow: DaPlayerState.PlayingNow(musicType: nil,
                                                                                state: TrackState(hash: WebSocketService.ownSignatureHash,
                                                                                                  progress: 0,
                                                                                                  isPlaying: false)),
                                           isBlocked: false),
                     allowedTimes: [:] )
    
    return BehaviorRelay(value: x)
    
}()

var appStateSlice: AppState {
    return _appState.value
}

var appState: Driver<AppState> {
    return _appState.asDriver()
}

struct AppState: Equatable {
    
    var player: DaPlayerState
    
//    let user: User
    var allowedTimes: [Int: UInt]
    
}

struct DaPlayerState: Equatable {
    
    var playlist: Playlist
    var playingNow: PlayingNow
    var isBlocked: Bool
    
    struct Playlist: Equatable {
        
        var tracks: DaPlaylist
        var lastPatch: ReduxViewPatch?
        var addons: [Addon] //stack
        var activeTrackHash: TrackOrderHash?
        
        struct ReduxViewPatch {
            let isOwn: Bool
            var patch: DaPlaylist.NullableReduxView
        };
    };
    
    struct PlayingNow: Equatable {
        
        var musicType: MusicType?
        var state: TrackState
        
        enum MusicType: Equatable {
            case addon(Addon)
            case track(Track)
        };
        
    };
    
}


enum Dispatcher {
    
    static let actions = BehaviorSubject<[ActionCreator]>(value: [])
    
    static func kickOff() {
        
        let newItem = actions.asObservable()
            .filter { $0.count > 0 }
            .map { $0.first! }
        
        ////kick off loop
        recursivelyLoad(nextPageTrigger: newItem)
            .subscribe()
            //.disposed(by: bag)
        
    }
    
    static func recursivelyLoad(nextPageTrigger: Observable<ActionCreator>) -> Observable<AppState> {
        
        return nextPageTrigger
            .take(1)
            .delay(0, scheduler: MainScheduler.instance) ///TODO: get rid of jumping into next run loop
            .flatMap { actionCreator in
                actionCreator.perform(initialState: _appState.value)
                    .do(onSuccess: { (newState) in
                        
                        guard newState != _appState.value else { return }
                        _appState.accept(newState)
                
                    })
            }
            .do(onNext: { (newState) in
                actions.onNext( Array(actions.unsafeValue.dropFirst()) )
            })
            .concat(Observable.deferred {
                self.recursivelyLoad(nextPageTrigger: nextPageTrigger)
            })
        
    }
    
    ///TODO: add proper logging for new AppState and actions dispatched
    static func dispatch(action: Action) {
        
        actions.onNext(actions.unsafeValue + [ActionCreatorWrapper(action: action)])
        
    }
    
    static func dispatch(action: ActionCreator) {
        
        actions.onNext(actions.unsafeValue + [action])
        
    }
    
}

protocol Action {
    
    func perform( initialState: AppState ) -> AppState
    
}

protocol ActionCreator {
    
    func perform( initialState: AppState ) -> Single<AppState>
    
}

struct ActionCreatorWrapper: ActionCreator {
    let action: Action
    
    func perform(initialState: AppState) -> Single<AppState> {
        return .just( action.perform(initialState: initialState) )
    }
    
}

////shorthands
extension AppState {
    
    var currentTrack: OrderedTrack? {
        guard let hash = player.playlist.activeTrackHash,
              let t = player.playlist.tracks[hash] else {
                return nil
        }
        
        return t
    }
 
//    var canForward: Driver<Bool> {
//        
//        
//        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized && self.playlist.hasPlaylisItems }
//        
//        switch currentQueueItem.content {
//        case .addon(let addon): return addon.type == .artistBIO || addon.type == .songCommentary
//        default: break
//        }
//        
//        return self.state.initialized
//    }
//    
//    var canBackward: Bool {
//        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized && self.playlist.hasPlaylisItems}
//        
//        switch currentQueueItem.content {
//        case .addon(let addon): return addon.type == .artistBIO || addon.type == .songCommentary
//        case .track(_), .stub(_):
//            guard let trackProgress = self.currentTrackState?.progress, trackProgress > 0.3 else { return self.state.initialized }
//            return true
//        }
//    }
//    
//    var canSeek: Bool {
//        guard self.state.initialized, let currentQueueItem = self.playerQueue.currentItem else { return false }
//        
//        switch currentQueueItem.content {
//        case .addon(_), .stub(_): return false
//        case .track(_): return self.state.waitingAddons == false
//        }
//    }
//    
}
