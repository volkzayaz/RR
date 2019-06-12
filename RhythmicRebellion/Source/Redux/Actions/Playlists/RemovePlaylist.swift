//
//  RemovePlaylist.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/12/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct RemovePlaylist: Action {
    
    let playlist: FanPlaylist
    
    func perform(initialState: AppState) -> AppState {
        var x = initialState
        
        var p = x.player.myPlaylists
        
        p.removeAll(where: { $0 == playlist })
        
        x.player.myPlaylists = p
        
        return x
    }
    
}
