//
//  SetNewUser.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/2/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct SetNewUser: Action {
    
    let user: User
    
    func perform(initialState: AppState) -> AppState {
        
        var state = initialState
        state.user = user
        
        
        ///TODO: hide this global state change inside AppState
        if let email = user.profile?.email {
            SettingsStore.lastSignedUserEmail.value = email
        }
        
        if user.isGuest { ///logout
            DownloadManager.default.clearArtifacts()
            DataLayer.get.pagesLocalStorageService.reset()
        }

        return state
    }
    
}
