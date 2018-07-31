//
//  Playlist.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Playlist: Codable {
    let id: Int
    let name: String
    let createdDate: Date?
    let updatedDate: Date?
    let isDefault: Bool
    let thumbnailURLString: String?
    let title: String
    let isLocked: Bool
    let sortOrder: Int

    var thumbnailURL: URL? {
        guard let thumbnailURLString = self.thumbnailURLString else { return nil }
        return URL(string: thumbnailURLString)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdDate = "created_at"
        case updatedDate = "updated_at"
        case isDefault = "is_default"
        case thumbnailURLString = "thumbnail"
        case title
        case isLocked = "is_locked"
        case sortOrder = "sort_order"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.createdDate = try container.decodeAsDate(String.self, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        self.updatedDate = try container.decodeAsDate(String.self, forKey: .updatedDate, dateFormatter: dateTimeFormatter)

        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
        self.thumbnailURLString = try container.decode(String.self, forKey: .thumbnailURLString)
        self.title = try container.decode(String.self, forKey: .title)
        self.isLocked = try container.decode(Bool.self, forKey: .isLocked)
        self.sortOrder = try container.decode(Int.self, forKey: .sortOrder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.createdDate, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.updatedDate, forKey: .updatedDate, dateFormatter: dateTimeFormatter)

        try container.encode(self.isDefault, forKey: .isDefault)
        try container.encode(self.thumbnailURLString, forKey: .thumbnailURLString)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.isLocked, forKey: .isLocked)
        try container.encode(self.sortOrder, forKey: .sortOrder)
    }
}

extension Playlist: Equatable {
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Playlist: Hashable {
    public var hashValue: Int { return self.id }
}

