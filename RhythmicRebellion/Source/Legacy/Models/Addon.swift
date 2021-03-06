//
//  Addon.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/10/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Addon: Codable {

    enum AddonType: Int, Codable {
        case advertisement = 0
        case songIntroduction = 1
        case songCommentary = 2
        case artistBIO = 3
        case artistAnnouncements = 4
        
        var title: String {
            switch self {
            case .songIntroduction: return NSLocalizedString("Intro", comment: "SongIntroduction addon title")
            case .songCommentary: return NSLocalizedString("Commentary", comment: "SongCommentary addon title")
            case .artistBIO: return NSLocalizedString("BIO", comment: "ArtistBIO addon title")
            case .artistAnnouncements: return NSLocalizedString("Announcement", comment: "ArtistAnnouncements addon title")
            case .advertisement: return ""
                
            }
        }
    }

    let id: Int
    let trackId: Int?
    let ownerId: String
    let title: String
    let isActive: Bool
    let startDate: Date?
    let endDate: Date?
    let createdDate: Date?
    let updatedDate: Date?
    let audioFile: TrackAudioFile

    let type: AddonType

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case trackId = "record_id"
        case ownerId = "owner_id"
        case title
        case isActive = "is_active"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
        case audioFile = "audio_file"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.type = try container.decode(AddonType.self, forKey: .type)
        self.trackId = try? container.decode(Int.self, forKey: .trackId)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.title = try container.decode(String.self, forKey: .title)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.startDate = try container.decodeAsDate(String.self, forKey: .startDate, dateFormatter: dateTimeFormatter)
        self.endDate = try container.decodeAsDate(String.self, forKey: .endDate, dateFormatter: dateTimeFormatter)
        self.createdDate = try container.decodeAsDate(String.self, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        self.updatedDate = try container.decodeAsDate(String.self, forKey: .updatedDate, dateFormatter: dateTimeFormatter)

        self.audioFile = try container.decode(TrackAudioFile.self, forKey: .audioFile)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.trackId, forKey: .trackId)
        try container.encode(self.ownerId, forKey: .ownerId)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.isActive, forKey: .isActive)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.startDate, forKey: .startDate, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.endDate, forKey: .endDate, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.createdDate, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.updatedDate, forKey: .updatedDate, dateFormatter: dateTimeFormatter)

        try container.encode(self.audioFile, forKey: .audioFile)
    }
}

extension Addon: Equatable {
    static func == (lhs: Addon, rhs: Addon) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Addon: Hashable {
    public var hashValue: Int { return self.id }
}

