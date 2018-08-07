//
//  TrackItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackViewModel: TrackTableViewCellViewModel {

    var id: String { return String(track.id) }

    var title: String { return track.name }
    var description: String { return track.radioInfo }

    let track: Track
}
