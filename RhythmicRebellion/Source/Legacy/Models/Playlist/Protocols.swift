//
//  Protocols.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

//Any entity that can be represented as Playlist (UserPlaylist, Recommended, Album...)
protocol Playlist {
    
    var id: Int {get}
    var name: String {get}
    var isDefault: Bool {get}
    var thumbnailURL: URL? {get}
    
    var description: String? {get}
    var title: String? {get}
    
}

///Entity capable of providing list of Tracks
enum ThumbMode {
    case index
    case artwork
}; protocol TrackProvider {

    var mode: ThumbMode { get }
    
    ////provide list of tracks to play back
    func provide() -> Observable<[TrackRepresentation]>
    
}

protocol PlaylistProvider: TrackProvider {
    var playlist: Playlist { get }
}
extension PlaylistProvider {
    var mode : ThumbMode { return .index }
}


protocol DeletablePlaylistProvider: PlaylistProvider {
    var canDelete: Bool { get }
    func delete(track: Track) -> Maybe<Void>
    func drop() -> Maybe<Void> ///deletes whole playlist
}

////
protocol ClearablePlaylistProvider: PlaylistProvider {
    func clear() -> Maybe<Void>
}


protocol DownloadablePlaylistProvider: PlaylistProvider {
    
    var downloadable: Maybe<Downloadable> { get }
    var instantDownload: Bool { get }
    
}

protocol AttachableProvider {
    
    func attach(to playlist: FanPlaylist) -> Maybe<Void>
    
}
