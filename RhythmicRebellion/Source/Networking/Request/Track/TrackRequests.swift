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
}

extension TrackRequest {

    func asURLRequest() throws -> URLRequest {

        switch self {
        case .lyricks(let track):
            return anonymousRequest(method: .get,
                                    path: "player/record/" + String(track.id) + "/lyrics-karaoke")
        }
    }
}
