//
//  Playlist.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol PlaylistShortInfo {
    var id: Int {get}
    var name: String {get}
    var isDefault: Bool {get}
    var thumbnailURL: URL? {get}
    
    var description: String? {get}
    var title: String? {get}
    
    var isFanPlaylist: Bool {get}
}

struct Playlist: PlaylistShortInfo, Codable {
    let id: Int
    let name: String
    let createdDate: Date?
    let updatedDate: Date?
    let isDefault: Bool
    let thumbnailURLString: String?
    let description: String?
    let title: String?
    let isLocked: Bool
    let sortOrder: Int
    
    let isFanPlaylist: Bool = false
    
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
        case description
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
        self.description = try container.decode(String.self, forKey: .description)
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



struct PlaylistShort: PlaylistShortInfo, Codable {
    let id: Int
    let name: String
    let isDefault: Bool
    let description: String?
    let title: String?
    let thumbnailURL: URL?
    
    let isFanPlaylist: Bool = true
//    var thumbnailURL: URL? {
//        guard let thumbnailURLString = self.thumbnailURLString else { return nil }
//        return URL(string: thumbnailURLString)
//    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDefault = "is_default"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        self.isDefault = (try? container.decode(Bool.self, forKey: .isDefault)) ?? false
        self.description = nil
        self.title = nil        
        self.thumbnailURL = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.isDefault, forKey: .isDefault)
    }
}

extension PlaylistShort: Equatable {
    static func == (lhs: PlaylistShort, rhs: PlaylistShort) -> Bool {
        return lhs.id == rhs.id
    }
}

extension PlaylistShort: Hashable {
    public var hashValue: Int { return self.id }
}

