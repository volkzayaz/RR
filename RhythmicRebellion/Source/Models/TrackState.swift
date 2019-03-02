//
//  TrackState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackState: Codable, Equatable {

    ///it is important that every TrackState change is signed with correct hash
    ///therefore progress and isPlaying fields are immutable
    ///we do so to enforce users to create new TrackState with correct hash,
    ///rather than reuse existing trackState and potentially forget, to update hash
    
    let hash: String
    let progress: TimeInterval
    let isPlaying: Bool

    init(hash: String = WebSocketService.ownSignatureHash, progress: TimeInterval, isPlaying: Bool) {
        self.hash = hash
        self.progress = progress
        self.isPlaying = isPlaying
    }
 
    var isOwn: Bool {
        return hash == WebSocketService.ownSignatureHash
    }
    
}
