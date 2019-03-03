//
//  DefaultKaraokeIntervalViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct DefaultKaraokeIntervalViewModel: KaraokeIntervalCellViewModel {

    var text: String? { return karaokeInterval.content }
    let font: UIFont

    let karaokeInterval: KaraokeInterval

}
