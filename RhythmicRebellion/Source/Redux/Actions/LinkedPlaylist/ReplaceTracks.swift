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
        var tracks = initialState.player.tracks
        
        ///getting state transform
        tracks.clear() ///otherwise patch will try to insert tracks in the beggining
        let patch = tracks.insertPatch(tracks: with, after: nil)
        
        ///mapping state transform
        let reduxPatch = PlayerState.ReduxViewPatch(shouldFlush: true, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: with).perform(initialState: initialState)
        
    }
    
}
