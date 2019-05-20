//
//  AppendPlaylist.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/20/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct AppendPlaylists: Action {
    
    let playlists: [FanPlaylist]
    
    func perform(initialState: AppState) -> AppState {
        var x = initialState
        
        x.player.myPlaylists = x.player.myPlaylists + playlists
        
        return x
    }
    
}
