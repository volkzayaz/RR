//
//  ClearTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct ClearTracks: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        let reduxPatch = PlayerState.ReduxViewPatch(isOwn: true, shouldFlush: true, patch: [:])
        
        return ApplyReduxViewPatch(viewPatch: reduxPatch,
                                   assosiatedTracks: []).perform(initialState: initialState)
    }
    
}
