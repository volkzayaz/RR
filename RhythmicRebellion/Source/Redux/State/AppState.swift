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

fileprivate let _appState: BehaviorRelay<AppState> = {
    
    let x = AppState(player: PlayerState(tracks: LinkedPlaylist(),
                                           lastPatch: nil,
                                           currentItem: nil,
                                           isBlocked: false)
                    )
    
    return BehaviorRelay(value: x)
    
}()

var appStateSlice: AppState {
    return _appState.value
}

var appState: Driver<AppState> {
    return _appState.asDriver()
}

struct AppState: Equatable {
    
    var player: PlayerState
    
//    let user: User
    
}

struct PlayerState: Equatable {
    
    var tracks: LinkedPlaylist
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
        let shouldFlush: Bool
        var patch: LinkedPlaylist.NullableReduxView
    };
    
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
        
        guard let currentItem = player.currentItem,
              let t = currentTrack?.track else {
            return nil
        }
        
        if let a = currentItem.addons.first {
            return .addon(a)
        }
        
        return .track(t)
    }
    
}

extension Dispatcher {
    
    static var state: BehaviorRelay<AppState> {
        return _appState
    }
    
}
