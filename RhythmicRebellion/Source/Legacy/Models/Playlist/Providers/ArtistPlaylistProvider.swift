//
//  ArtistPlaylistProvider.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct ArtistPlaylistProvider: PlaylistProvider {
    
    let artistPlaylist: ArtistPlaylist
    
    func provide() -> Observable<[TrackRepresentation]> {
        return ArtistRequest.playlistRecords(playlist: artistPlaylist)
            .rx.response(type: BaseReponse<[Track]>.self)
            .map { $0.data.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
    var playlist: Playlist {
        return artistPlaylist
    }
    
}
