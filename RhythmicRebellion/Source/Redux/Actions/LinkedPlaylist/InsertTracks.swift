//
//  InsertTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct InsertTracks: ActionCreator {
    
    let tracks: [Track]
    let afterTrack: OrderedTrack?
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        let tracks = initialState.player.tracks
        
        ///getting state transform
        let patch = tracks.insertPatch(tracks: self.tracks, after: afterTrack)
        
        ///mapping state transform
        let reduxPatch = PlayerState.ReduxViewPatch(shouldFlush: false, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: self.tracks).perform(initialState: initialState)
        
    }
}
