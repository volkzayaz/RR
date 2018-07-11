//
//  Addon.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/10/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum AddonType: Int {
    case unknown = 0
    case SongIntroduction = 1
    case SongCommentary = 2
    case ArtistBIO = 3
    case ArtistAnnouncements = 4
}

struct Addon: Decodable {

    let id: Int
    let typeValue: Int
    let trackId: Int
    let ownerId: String
    let title: String
    let isActive: Bool
    let startDate: Date?
    let endDate: Date?
//    let createdDate: Date
//    let updatedDate: Date
    let audioFile: AudioFile

    var type: AddonType { return AddonType(rawValue: typeValue) ?? .unknown}

    enum CodingKeys: String, CodingKey {
        case id
        case typeValue = "type"
        case trackId = "record_id"
        case ownerId = "owner_id"
        case title
        case isActive = "is_active"
        case startDate = "start_date"
        case endDate = "end_date"
//        case createdDate = "created_at"
//        case updatedDate = "updated_at"
        case audioFile = "audio_file"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.typeValue = try container.decode(Int.self, forKey: .typeValue)
        self.trackId = try container.decode(Int.self, forKey: .trackId)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.title = try container.decode(String.self, forKey: .title)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)

        self.startDate = nil
        self.endDate = nil

        self.audioFile = try container.decode(AudioFile.self, forKey: .audioFile)
    }

}
