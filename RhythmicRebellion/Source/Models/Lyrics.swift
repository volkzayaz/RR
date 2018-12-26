//
//  Lyrics.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/14/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct KaraokeIntervals: Codable {

    let start: Double
    let end: Double
    let content: String

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case content
    }
}

struct Karaoke: Codable {

    let id: Int
    let trackId: Int
    let createdAt: Date?
    let updatedAt: Date?
    let isPublic: Bool
//    let metadata:
    let intervals: [KaraokeIntervals]

    enum CodingKeys: String, CodingKey {
        case id
        case trackId = "record_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPublic = "is_public"
//        case metadata
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
        self.intervals = try container.decode([KaraokeIntervals].self, forKey: .intervals)
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

public struct Lyrics: Codable {

    let id: Int
    let lyrics: String
    let karaoke: Karaoke?

    enum CodingKeys: String, CodingKey {
        case id
        case lyrics
        case karaoke = "transcript"
    }
}
