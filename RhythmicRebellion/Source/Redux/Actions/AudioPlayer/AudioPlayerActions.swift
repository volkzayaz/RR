//
//  AudioPlayerActions.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

extension AudioPlayer {
    
    ///TODO: prepare proper naming and documentation on OrganicScrub and skipSeek stuff
    struct OrganicScrub: ActionCreator {
        
        let newValue: TimeInterval
        
        func perform(initialState: AppState) -> Observable<AppState> {
            
            guard initialState.player.lastChangeSignatureHash.isOwn else {
                return .just(initialState)
            }
            
            var state = initialState
            
            guard let currentTrackState = state.player.currentItem?.state,
                let currentTrack = state.currentTrack else {
                    return .just(state)
            }
            
            ////Preview Rules
            
            if case .limit45? = currentTrack.track.previewType, newValue > 45 {
                return ProceedToNextItem().perform(initialState: initialState)
            }
            else if case .limit90? = currentTrack.track.previewType, newValue > 90 {
                return ProceedToNextItem().perform(initialState: initialState)
            }
            else if case .full? = currentTrack.track.previewType,
                let audioDuration = currentTrack.track.audioFile?.duration,
                let fullPreviewsAmount = currentTrack.track.previewLimitTimes,
                let μSecondsEllapsed = state.player.tracks.previewTime[currentTrack.track.id],
                (fullPreviewsAmount * audioDuration) - Int(μSecondsEllapsed / 1000) < 0,
                newValue > 45 {
                return ProceedToNextItem().perform(initialState: initialState)
            }
            
            
            state.player.currentItem?.state = .init(progress: newValue,
                                                    isPlaying: currentTrackState.isPlaying,
                                                    skipSeek: ())
            
            return .just(state)
            
        }
        
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
