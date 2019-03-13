//
//  AudioPlayerActions.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension AudioPlayer {
    
    ///TODO: prepare proper naming and documentation on OrganicScrub and skipSeek stuff
    struct OrganicScrub: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: newValue,
                                                isPlaying: currentTrackState.isPlaying,
                                                skipSeek: ())
        return state
        }
        
        let newValue: TimeInterval
    }
    
    struct Scrub: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: newValue,
                                                isPlaying: currentTrackState.isPlaying)
        return state
        }
        
        let newValue: TimeInterval
    }
    
    struct Pause: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: false,
                                                skipSeek: ())
        return state
        }
    }
    
    struct Play: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: true,
                                                skipSeek: ())
        return state
        }
    }
    
    struct Switch: Action { func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        
        guard let currentTrackState = state.player.currentItem?.state else {
            return state
        }
        
        state.player.currentItem?.state = .init(progress: currentTrackState.progress,
                                                isPlaying: !currentTrackState.isPlaying,
                                                skipSeek: ())
        return state
        }
    }
    
}
