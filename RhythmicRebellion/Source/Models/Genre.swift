//
//  Genre.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Genre: Codable {

    let id: Int?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    public init(with name: String) {
        self.id = nil
        self.name = name
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let id = self.id { try container.encode(id, forKey: .id) }
        try container.encode(self.name, forKey: .name)
    }
}

extension Genre: Equatable {
    static func == (lhs: Genre, rhs: Genre) -> Bool {
        guard let lhsId = lhs.id, let rhsId = rhs.id else { return lhs.name == rhs.name }
        return lhsId == rhsId
    }
}

extension Genre: Hashable {
    public var hashValue: Int { return self.name.hashValue }
}
