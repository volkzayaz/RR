//
//  UpdateUser.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/2/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct UpdateUser: Action {
    
    let update: (inout User?) -> Void

    func perform(initialState: AppState) -> AppState {
        var state = initialState
        var user = state.user
        update(&user)
        state.user = user
        return state
    }
    
}
