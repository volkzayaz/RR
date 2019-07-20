//
//  PlaylistProvider.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct FanPlaylistProvider: DeletablePlaylistProvider {
    
    let fanPlaylist: FanPlaylist
    var playlist: Playlist {
        return fanPlaylist
    }
    
    var canDelete: Bool { return !fanPlaylist.isDefault }
    
    func provide() -> Observable<[TrackRepresentation]> {
        return TrackRequest.fanTracks(playlistId: playlist.id)
            .rx.response(type: PlaylistTracksResponse.self)
            .map { $0.tracks.enumerated().map(TrackRepresentation.init) }
            .asObservable()
    }
    
    func delete(track: Track) -> Maybe<Void> {
        return PlaylistRequest.deleteTrack(track, from: fanPlaylist)
            .rx.emptyResponse()
    }
    
    func drop() -> Maybe<Void> {
        return PlaylistManager.delete(playlist: fanPlaylist)
    }
    
}

extension FanPlaylistProvider: ClearablePlaylistProvider {

    func clear() -> Maybe<Void> {
        return PlaylistRequest.clear(playlist: fanPlaylist)
            .rx.emptyResponse()
    }
    
}

//extension FanPlaylistProvider: AttachableProvider {
//    
//    func attach(to playlist: FanPlaylist) -> Maybe<Void> {
//        return PlaylistRequest.attach(playlist: fanPlaylist, to: playlist)
//            .rx.emptyResponse()
//    }
//    
//    var shouldIncludePlaylist: (FanPlaylist) -> Bool {
//        let id = fanPlaylist.id
//        return {
//            $0.id != id
//        }
//    }
//    
//}
