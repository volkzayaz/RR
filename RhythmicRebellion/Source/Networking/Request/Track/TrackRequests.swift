//
//  TrackRequests.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 1/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum TrackRequest: BaseNetworkRouter {

    case lyricks(track: Track)
    
    case fanTracks(playlistId: Int)
    case tracks(playlistId: Int)
    
}

extension TrackRequest {

    func asURLRequest() throws -> URLRequest {

        switch self {
        case .lyricks(let track):
            return anonymousRequest(method: .get,
                                    path: "player/record/" + String(track.id) + "/lyrics-karaoke")
            
        case .fanTracks(let playlistId):
            return anonymousRequest(method: .get,
                                    path: "fan/playlist/\(playlistId)/record")
            
        case .tracks(let playlistId):
            return anonymousRequest(method: .get,
                                    path: "player/records/\(playlistId)")
            
        }
    }
}
