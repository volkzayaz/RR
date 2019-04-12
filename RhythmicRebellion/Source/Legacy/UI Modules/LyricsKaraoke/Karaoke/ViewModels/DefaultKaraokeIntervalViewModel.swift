//
//  DefaultKaraokeIntervalViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import RxDataSources

struct KaraokeIntervalCellViewModel: IdentifiableType, Equatable {

    var text: String? { return karaokeInterval.content }
    let font: UIFont

    let karaokeInterval: KaraokeInterval

    var identity: ClosedRange<TimeInterval> {
        return karaokeInterval.range
    }
    
}
