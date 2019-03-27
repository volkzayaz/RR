//
//  ChangeLyricsMode.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/27/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ChangeLyricsMode: Action {
    
    let to: PlayerState.Lyrics.Mode
    
    func perform(initialState: AppState) -> AppState {
        
        ///Lyrics data must be present piro to changing lyrics mode
        guard let lyrics = initialState.player.currentItem?.lyrics else {
            fatalErrorInDebug("Can't change lyrics mode when there is no lyrics data for item: \(String(describing: initialState.player.currentItem?.activeTrackHash))")
            return initialState
        }
        
        ///Lyrics data must contain karaoke time intervals in order to use karaoke mode
        if case .karaoke(_) = to, lyrics.data.karaoke == nil {
            fatalErrorInDebug("Can't change lyrics mode to karaoke, since lyrics data does not contain karaoke metadata")
            return initialState
        }
        
        ///Track must contain backing track file info in order to use backingTrack mode
        if case .karaoke(let config) = to,
           case .backing = config.track,
           initialState.currentTrack?.track.backingAudioFile == nil {
            fatalErrorInDebug("Can't change karaoke track mode to backingTrack, since \(String(describing: initialState.currentTrack?.track)) does not contain backing track")
            return initialState
        }
        
        var state = initialState
        state.player.currentItem?.lyrics?.mode = to
        
        if case .karaoke(let x)? = initialState.player.currentItem?.lyrics?.mode,
           case .karaoke(let y)  = to,
            x.track != y.track { ///changing vocal to backing or vice versa
            
            ///starting track over
            state.player.currentItem?.state = .init(progress: 0,
                                                    isPlaying: true)
            
        }
           
        
        return state
    }
    
}
