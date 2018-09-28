//
//  PlayerTrack.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/20/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


struct PlayerTrack {
    let track: Track
    let playlistItem: PlayerPlaylistItem
    
    var trackId : TrackId {
        return TrackId(id: track.id, key: playlistItem.trackKey)
    }
}
