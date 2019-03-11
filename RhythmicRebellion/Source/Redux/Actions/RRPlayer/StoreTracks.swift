//
//  StoreTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct StoreTracks: Action {
    
    let tracks: [Track]
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        
        tracks.forEach { state.player.tracks.trackDump[$0.id] = $0 }
        
        return state
    }
    
}
