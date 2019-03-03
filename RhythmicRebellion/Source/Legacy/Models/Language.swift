//
//  Language.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Language: Codable {

    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name = "label"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
    }
}

extension Language: Equatable {
    static func == (lhs: Language, rhs: Language) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Language: Hashable {
    public var hashValue: Int { return self.id.hashValue }
}
