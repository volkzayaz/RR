//
//  ScrubToFractionAction.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ScrubToFraction: Action {
    
    let fraction: Float
    
    func perform(initialState: AppState) -> AppState {
        
        guard let secs = initialState.currentTrack?.track.audioFile?.duration else {
            return initialState
        }
        
        return AudioPlayer.Scrub(newValue: TimeInterval(secs) * Double(fraction)).perform(initialState: initialState)
    }
    
}
