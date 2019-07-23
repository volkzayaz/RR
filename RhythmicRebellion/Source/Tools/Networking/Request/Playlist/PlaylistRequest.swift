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
    case rename(playlist: FanPlaylist, newName: String) ///FanPlaylist
    case clear(playlist: FanPlaylist)/// Void
    
    case attachTracks(_ tracks: [Track],         to: FanPlaylist) ///AttachTracksResponse
    
    case attachRR    (playlist: DefinedPlaylist, to: FanPlaylist) ///Void
    case attach      (playlist: FanPlaylist,     to: FanPlaylist) ///AttachTracksResponse
    case attachAlbum (album   : Album,           to: FanPlaylist) ///Void
    case attachArtist(playlist: ArtistPlaylist,  to: FanPlaylist) ///Void
    
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
            
        case .rename(let playlist, let newName):
            return anonymousRequest(method: .put,
                                    path: "fan/playlist/\(playlist.id)",
                                    params: ["id": playlist.id,
                                             "name": newName,
                                             "is_default": false])
            
        case .clear(let playlist):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(playlist.id)/clear")
            
        case .attachRR(let rrPlaylist, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-playlists",
                                    params: ["playlist_id": rrPlaylist.id])
        
        case .attach(let playlist, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-fan-playlists",
                params: ["playlist_id": playlist.id])
            
        case .attachTracks(let tracks, let to):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-items",
                                    params: ["records": tracks.map { ["id" : $0.id] } ])
         
        case .attachAlbum(let album, let to):
            
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-items",
                                    params: ["albums": [ ["id" : album.id] ] ])
        
        case .attachArtist(let playlist, let to):
            
            return anonymousRequest(method: .post,
                                    path: "fan/playlist/\(to.id)/attach-artist-playlists",
                                    params: ["playlist_id": playlist.id ])
            
        case .deleteTrack(let track, let from):
            return anonymousRequest(method: .delete,
                                    path: "fan/playlist/\(from.id)/record/\(track.id)")
            
        }
    }
}
