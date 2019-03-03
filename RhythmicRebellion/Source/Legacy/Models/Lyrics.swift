//
//  Lyrics.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/14/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct KaraokeInterval: Codable {

    let start: Double
    let end: Double
    let content: String
}

extension KaraokeInterval: Equatable {
    public static func == (lhs: KaraokeInterval, rhs: KaraokeInterval) -> Bool {
        return lhs.start == rhs.start
                && lhs.end == rhs.end
                && lhs.content == rhs.content
    }
}

struct Karaoke: Codable {

    let id: Int
    let trackId: Int
    let createdAt: Date?
    let updatedAt: Date?
    let isPublic: Bool
    let intervals: [KaraokeInterval]

    enum CodingKeys: String, CodingKey {
        case id
        case trackId = "record_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPublic = "is_public"
        case intervals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        self.id = try container.decode(Int.self, forKey: .id)
        self.trackId = try container.decode(Int.self, forKey: .trackId)
        self.createdAt = try container.decodeAsDate(String.self, forKey: .createdAt, dateFormatter: dateTimeFormatter)
        self.updatedAt = try container.decodeAsDate(String.self, forKey: .updatedAt, dateFormatter: dateTimeFormatter)
        self.isPublic = try container.decode(Bool.self, forKey: .isPublic)
        self.intervals = try container.decode([KaraokeInterval].self, forKey: .intervals)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        try container.encode(self.id, forKey: .id)
        try container.encode(self.trackId, forKey: .trackId)
        try container.encodeAsString(self.createdAt, forKey: .createdAt, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.updatedAt, forKey: .updatedAt, dateFormatter: dateTimeFormatter)
        try container.encode(self.isPublic, forKey: .isPublic)
        try container.encode(self.intervals, forKey: .intervals)
    }
}

extension Karaoke: Equatable {
    public static func == (lhs: Karaoke, rhs: Karaoke) -> Bool {
        return lhs.id == rhs.id
            && lhs.trackId == rhs.trackId
            && lhs.createdAt == rhs.createdAt
            && lhs.updatedAt == rhs.updatedAt
            && lhs.isPublic == rhs.isPublic
            && lhs.intervals == rhs.intervals
    }
}



public struct Lyrics: Codable {

    let id: Int
    let lyrics: String?
    let karaoke: Karaoke?

    enum CodingKeys: String, CodingKey {
        case id
        case lyrics
        case karaoke = "transcript"
    }
}


extension Lyrics: Equatable {
    public static func == (lhs: Lyrics, rhs: Lyrics) -> Bool {
        return lhs.id == rhs.id
            && lhs.lyrics == rhs.lyrics
            && lhs.karaoke == rhs.karaoke
    }
}
