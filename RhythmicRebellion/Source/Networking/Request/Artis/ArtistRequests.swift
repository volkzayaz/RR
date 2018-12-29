//
//  ArtistRequests.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum ArtistRequest: BaseNetworkRouter {
    
    case albums(artist: Artist)
    case playlists(artist: Artist)
    
    case records(artist: Artist)
    case playlistRecords(playlist: ArtistPlaylist)
    case albumRecords(album: Album)
    
    
}

extension ArtistRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
        case .albums(let artist):
            return anonymousRequest(method: .get,
                                    path: "fan/artist/albums-of-artist/\(artist.id)")
            
        case .playlists(let artist):
            return anonymousRequest(method: .get,
                                    path: "fan/artist/playlists-of-artist/\(artist.id)")
            
        case .records(let artist):
            return anonymousRequest(method: .get,
                                    path: "fan/artist/records/\(artist.id)")
            
        case .playlistRecords(let playlist):
            return anonymousRequest(method: .get,
                                    path: "fan/artist/records-of-artist-playlist/\(playlist.id)")
        
        case .albumRecords(let album):
            return anonymousRequest(method: .get,
                                    path: "fan/artist/records-of-album/\(album.id)")
            
        }
        
    }
    
}
