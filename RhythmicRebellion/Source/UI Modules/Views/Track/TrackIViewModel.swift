//
//  TrackItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit



struct TrackViewModel: TrackTableViewCellViewModel {

    var id: String { return String(track.id) }

    var title: String { return track.name }
    var description: String { return track.radioInfo }
    var isPlayable: Bool { return track.isPlayable }

    let track: Track
    
    var isCurrentInPlayer: Bool
    var isPlaying: Bool

    var isCensorship: Bool
    var previewOptionsImage: UIImage?

    var downloadState: TrackDownloadState?

}
