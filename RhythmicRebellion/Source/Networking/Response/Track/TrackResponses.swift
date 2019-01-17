//
//  RxResponse.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 1/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackResponse<T: Decodable>: Decodable {
    let data: T
}
