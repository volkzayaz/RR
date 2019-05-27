//
//  ReplaceTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct ReplaceTracks: ActionCreator {
    
    let with: [Track]
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        var state = initialState
        var tracks = initialState.player.tracks
        
        ///getting state transform
        tracks.clear() ///otherwise patch will try to insert tracks in the beggining
        state.player.tracks = tracks
        
        return AddTracksToLinkedPlaying(tracks: with, style: .now)
            .perform(initialState: state)
        
    }
    
}
