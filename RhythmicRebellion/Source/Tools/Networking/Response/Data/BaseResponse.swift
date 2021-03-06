//
//  BaseReponse.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/15/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct BaseReponse<T: Decodable>: Decodable {
    let data: T
}
