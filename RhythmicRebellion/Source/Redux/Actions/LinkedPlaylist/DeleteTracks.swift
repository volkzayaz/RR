//
//  DeleteTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct DeleteTrack: ActionCreator {
    
    let track: OrderedTrack
    let isOwnChange: Bool
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///initial state
        let tracks = initialState.player.tracks
        
        ///getting state transform
        let patch = tracks.deletePatch(track: track)
        
        ///mapping state transform
        let reduxPatch = PlayerState.ReduxViewPatch(isOwn: isOwnChange, shouldFlush: false, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: []).perform(initialState: initialState)
        
    }
}
