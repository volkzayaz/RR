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
    
    let x = AppState(player: DaPlayerState(tracks: DaPlaylist(),
                                           lastPatch: nil,
                                           currentItem: nil,
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
    
    var tracks: DaPlaylist
    var lastPatch: ReduxViewPatch?
    
    var currentItem: CurrentItem?
    
    struct CurrentItem: Equatable {
        let activeTrackHash: TrackOrderHash
        var addons: [Addon] //stack
        var state: TrackState
    }
    
    var isBlocked: Bool
    
    struct ReduxViewPatch {
        let isOwn: Bool
        var patch: DaPlaylist.NullableReduxView
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
            .flatMap { actionCreator -> Single<AppState> in
                
                let preState = actionCreator.prepare(initialState: _appState.value)
                if preState != _appState.value { _appState.accept(preState) }
                
                return actionCreator.perform(initialState: _appState.value)
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
    
    ///in case your operation is heavy you might need tot quickly prepare app state for such operation
    ///TODO: get rid of preapre and move to proper redux reducers
    func prepare( initialState: AppState ) -> AppState
    
    func perform( initialState: AppState ) -> Single<AppState>
    
}

extension ActionCreator {
    func prepare(initialState: AppState) -> AppState {
        return initialState
    }
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
        guard let hash = player.currentItem?.activeTrackHash,
              let t = player.tracks[hash] else {
                return nil
        }
        
        return t
    }
    
    var nextTrack: OrderedTrack? {
        guard let c = currentTrack else { return nil }
        
        return player.tracks.next(after: c.orderHash)
    }
    
    var firstTrack: OrderedTrack? {
        return player.tracks.orderedTracks.first
    }
 
    var canForward: Bool {
        
        guard case .addon(let addon)? = activePlayable else {
            return true
        }
        
        return addon.type == .artistBIO || addon.type == .songCommentary
        
    }

    var canBackward: Bool {
        
        return canForward
        
        ///TODO: understand why this piece of logic is present here
        
//        case .track(_), .stub(_):
//            guard let trackProgress = self.currentTrackState?.progress, trackProgress > 0.3 else { return self.state.initialized }
        
        
    }

    var canSeek: Bool {
        
        if case .track(_)? = activePlayable {
            return true
        }
        
        return false
    }
    
    enum MusicType: Equatable {
        case addon(Addon)
        case track(Track)
    };
    var activePlayable: MusicType? {
        
        guard let currentItem = player.currentItem else {
            return nil
        }
        
        if let a = currentItem.addons.first {
            return .addon(a)
        }
        
        return .track(currentTrack!.track)
    }
    
}
