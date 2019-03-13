//
//  TrackState.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackState: Codable, Equatable {

    enum CodingKeys: String, CodingKey {
        case hash, progress, isPlaying
    }
    
    ///it is important that every TrackState change is signed with correct hash
    ///therefore progress and isPlaying fields are immutable
    ///we do so to enforce users to create new TrackState with correct hash,
    ///rather than reuse existing trackState and potentially forget, to update hash
    
    let hash: String
    let progress: TimeInterval
    let isPlaying: Bool

    ///TODO: remove skipSeek hack. Unify |progress| and seek request into single Entity
    let skipSeek: Void?
    
    init(hash: String = WebSocketService.ownSignatureHash, progress: TimeInterval, isPlaying: Bool, skipSeek: Void? = nil) {
        self.hash = hash
        self.progress = progress
        self.isPlaying = isPlaying
        self.skipSeek = skipSeek
    }
 
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        hash = try c.decode(String.self, forKey: .hash)
        progress = try c.decode(TimeInterval.self, forKey: .progress)
        isPlaying = try c.decode(Bool.self, forKey: .isPlaying)
        
        skipSeek = nil
    }
    
    var isOwn: Bool {
        return hash == WebSocketService.ownSignatureHash
    }
    
    static func ==(lhs: TrackState, rhs: TrackState) -> Bool {
        return lhs.hash == rhs.hash &&
               lhs.progress == rhs.progress &&
               lhs.isPlaying == rhs.isPlaying &&
               (lhs.skipSeek == nil) == (rhs.skipSeek == nil)
    }
    
}
