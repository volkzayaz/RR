//
//  OrderedTrack.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

typealias TrackOrderHash = String

struct OrderedTrack: Equatable {
    
    let track: Track
    let orderHash: TrackOrderHash
    
    init(track: Track, hash: String? = nil) {
        self.track = track
        orderHash = hash ?? String(randomWithLength: 5, allowedCharacters: .alphaNumeric)
    }
    
    func reduxView(previousTrack: OrderedTrack? = nil,
                   nextTrack    : OrderedTrack? = nil) -> [LinkedPlaylist.ViewKey: Any?] {
        
        var res: [LinkedPlaylist.ViewKey: Any?] = [ .id       : track.id,
                                                    .hash     : orderHash,
                                                    .previous : nil,
                                                    .next     : nil ]
        
        if let x = previousTrack {
            res[.previous] = x.orderHash
        }
        
        if let x = nextTrack {
            res[.next] = x.orderHash
        }
        
        return res
    }
    
    static func ==(lhs: OrderedTrack, rhs: OrderedTrack) -> Bool {
        return lhs.orderHash == rhs.orderHash
    }
    
}
