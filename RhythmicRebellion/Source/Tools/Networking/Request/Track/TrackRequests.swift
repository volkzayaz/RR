//
//  TrackRequests.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum TrackRequest: BaseNetworkRouter {

    case lyrics(track: Track)
    
    case fanTracks(playlistId: Int)
    case tracks(playlistId: Int)
    
    
    case addons(trackIds: [Int])
    case artist(artistId: String)
    
}

extension TrackRequest {

    func asURLRequest() throws -> URLRequest {

        switch self {
        case .lyrics(let track):
            return anonymousRequest(method: .get,
                                    path: "player/record/\(track.id)/lyrics-karaoke")
            
        case .fanTracks(let playlistId):
            return anonymousRequest(method: .get,
                                    path: "fan/playlist/\(playlistId)/record")
            
        case .tracks(let playlistId):
            return anonymousRequest(method: .get,
                                    path: "player/records/\(playlistId)")
            
        case .addons(let trackIds):
            
            let jsonQuery = ["filters" : ["record_id" : ["in" : trackIds]]]
            
            let data = try JSONSerialization.data(withJSONObject: jsonQuery)
            let param = String(data: data, encoding: .utf8)!
            
            return anonymousRequest(method: .get,
                                    path: "player/audio-add-ons-for-tracks",
                                    params: ["jsonQuery" : param],
                                    encoding: URLEncoding.queryString)
            
        case .artist(let artistId):
            
            let jsonQuery = ["filters" : ["id" : ["in" : [artistId]]]]
            
            let data = try JSONSerialization.data(withJSONObject: jsonQuery)
            let param = String(data: data, encoding: .utf8)!
            
            return anonymousRequest(method: .get,
                                    path: "player/artist",
                                    params: ["jsonQuery" : param],
                                    encoding: URLEncoding.queryString)
            
        }
    }
}




