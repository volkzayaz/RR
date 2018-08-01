//
//  PlaylistViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct PlaylistItemViewModel: PlaylistItemCollectionViewCellViewModel {

    var id: String { return String(playlist.id) }

    var title: String { return playlist.name }
    var description: String { return playlist.title }

    var thumbnailURL: URL? { return playlist.thumbnailURL }

    let playlist: Playlist
}
