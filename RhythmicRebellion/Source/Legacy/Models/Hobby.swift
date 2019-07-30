//
//  Hobby.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Hobby: Codable {

    let name: String

    enum CodingKeys: String, CodingKey {
        case name = "label"
    }

    public init(with name: String) {
        self.name = name
    }
}

extension Hobby: Equatable, Hashable {
}

