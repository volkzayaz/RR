//
//  ReplacePlaylists.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/20/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ReplacePlaylists: Action {
    
    let playlists: [FanPlaylist]
    
    func perform(initialState: AppState) -> AppState {
        var x = initialState
        
        x.player.myPlaylists = playlists
        
        return x
    }
    
}

struct SubstitutePlaylist: Action {
    
    let new: FanPlaylist
    
    func perform(initialState: AppState) -> AppState {
        var x = initialState
     
        if let i = x.player.myPlaylists.firstIndex(where: { $0.id == new.id }) {
            x.player.myPlaylists[i] = new
        }
        
        return x
    }
    
}
