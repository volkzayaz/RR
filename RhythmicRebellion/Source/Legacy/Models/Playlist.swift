//
//  Playlist.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol Playlist {
    var id: Int {get}
    var name: String {get}
    var isDefault: Bool {get}
    var thumbnailURL: URL? {get}
    
    var description: String? {get}
    var title: String? {get}
    
    var isFanPlaylist: Bool {get}
}

extension Playlist where Self: Equatable {
    static func ==(rhs: Playlist, lhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

struct DefinedPlaylist: Playlist, Codable {
    let id: Int
    let name: String
    let isDefault: Bool
    let thumbnailURLString: String?
    let description: String?
    let title: String?
    let isLocked: Bool
    
    let isFanPlaylist: Bool = false
    
    var thumbnailURL: URL? {
        guard let thumbnailURLString = self.thumbnailURLString else { return nil }
        return URL(string: thumbnailURLString)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isDefault = "is_default"
        case thumbnailURLString = "thumbnail"
        case description
        case title
        case isLocked = "is_locked"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        self.isDefault = try container.decode(Bool.self, forKey: .isDefault)
        self.thumbnailURLString = try container.decode(String.self, forKey: .thumbnailURLString)
        self.description = try container.decode(String.self, forKey: .description)
        self.title = try container.decode(String.self, forKey: .title)
        self.isLocked = try container.decode(Bool.self, forKey: .isLocked)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        
        try container.encode(self.isDefault, forKey: .isDefault)
        try container.encode(self.thumbnailURLString, forKey: .thumbnailURLString)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.isLocked, forKey: .isLocked)
    }
}

extension DefinedPlaylist: Equatable {
}

extension DefinedPlaylist: Hashable {
    public var hashValue: Int { return self.id }
}

struct FanPlaylist: Playlist, Codable {
    let id: Int
    let name: String
    let isDefault: Bool

    var description: String? { return nil }
    var title: String? { return nil }
    var thumbnailURL: URL? { return nil }
    
    let isFanPlaylist: Bool = true

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
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.isDefault, forKey: .isDefault)
    }
}

extension FanPlaylist: Equatable {
}

extension FanPlaylist: Hashable {
    public var hashValue: Int { return self.id }
}


struct ArtistPlaylist: Playlist, Codable, Equatable {
    
    let id: Int
    let name: String
    let coverImage: Image
    
    
    var isDefault: Bool {
        return false
    }
    
    var isFanPlaylist: Bool {
        return false
    }
    
    var thumbnailURL: URL? {
        guard let str = coverImage.simpleURL,
              let url = URL(string: str) else {
            return nil
        }
        
        return url
    }
    
    var description: String? {
        return nil
    }
    
    var title: String? {
        return nil
    }
    
}
