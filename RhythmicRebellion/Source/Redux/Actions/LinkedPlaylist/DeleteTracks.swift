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
        let shouldFlush = tracks.count == 1 ///WebSite requires separate "flush" call for last delete cases
        let patch = shouldFlush ? [:] : tracks.deletePatch(track: track)
        
        ///mapping state transform
        let reduxPatch = PlayerState.ReduxViewPatch(isOwn: isOwnChange, shouldFlush: shouldFlush, patch: patch)
        
        ///applying state transform
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: []).perform(initialState: initialState)
        
    }
}
