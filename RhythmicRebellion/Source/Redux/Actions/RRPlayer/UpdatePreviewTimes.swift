//
//  UpdatePreviewTimes.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct UpdateTrackPrviewTimes: Action {
    
    let newPreviewTimes: [Int: UInt64]
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        
        var oldState = state.player.tracks.previewTime
        newPreviewTimes.forEach { (key, value) in
            oldState[key] = value
        }
        state.player.tracks.previewTime = oldState
        
        return state
    }
    
}
