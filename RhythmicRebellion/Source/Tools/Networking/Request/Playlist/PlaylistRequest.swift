//
//  PlaylistRequest.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/3/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum PlaylistRequest: BaseNetworkRouter {
    
    case fanList /// [FanPlaylist]
    case rrList //// [DefinedPlaylist]
    
    case create(name: String) ///returns FanPlaylist
    case delete(playlist: FanPlaylist)/// Void
    case clear(playlist: FanPlaylist)/// Void
    
    case attachRR    (playlist: DefinedPlaylist, to: FanPlaylist) ///Void
    case attach      (playlist: FanPlaylist,     to: FanPlaylist) ///AttachTracksResponse
    case attachTracks(_ tracks: [Track],         to: FanPlaylist) ///AttachTracksResponse
    
    case deleteTrack(_ track: Track, from: FanPlaylist) ///Void
    
}

extension PlaylistRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .fanList:
            return anonymousRequest(method: .get,
                                    path: "fan/playlist")

        case .rrList:
            return anonymousRequest(method: .get,
                                    path: "player/playlists")
            
        case .create(let name):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist",
                                    params: ["name": name])
            
            
        case .delete(let playlist):
            return anonymousRequest(method: .delete,
                                    path: "fan/playlist/\(playlist.id)")
            
        case .clear(let playlist):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(playlist.id)/clear")
            
        case .attachRR(let rrPlaylist, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/playlists",
                                    params: ["playlist_id": rrPlaylist.id])
        
        case .attach(let playlist, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-fan-playlists",
                params: ["playlist_id": playlist.id])
            
        case .attachTracks(let tracks, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-items",
                                    params: ["records": tracks.map { ["id" : $0.id] } ])
         
        case .deleteTrack(let track, let from):
            return anonymousRequest(method: .delete,
                                    path: "fan/playlist/\(from.id)/record/\(track.id)")
            
        }
    }
}
