//
//  DefinedPlaylistProvider.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct DefinedPlaylistProvider: PlaylistProvider {
    
    let data: DefinedPlaylist
    var playlist: Playlist { return data }
    //let playlist: Playlist
    
    func provide() -> Observable<[TrackRepresentation]> {
        return TrackRequest.tracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
}

extension DefinedPlaylistProvider: AttachableProvider {
    
    func attach(to playlist: FanPlaylist) -> Maybe<Void> {
        return PlaylistRequest.attachRR(playlist: data, to: playlist)
            .rx.emptyResponse()
    }
    
}
