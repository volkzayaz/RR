//
//  ChangeBlockState.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ChangePlayerBlockState: Action {
    
    let isBlocked: Bool
    
    func perform(initialState: AppState) -> AppState {
        var state = initialState
        state.player.isBlocked = isBlocked
        return state
    }
    
}
