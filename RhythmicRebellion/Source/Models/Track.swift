//
//  Track.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum PreviewType: Int {
    case unknown
    case noPreview = 1
    case full = 2
    case limit45 = 3
    case limit90 = 4
}

public struct Track: Codable {

    let id: Int
    let songId: Int
    let name: String
    let radioInfo: String
    let ownerId: String
    let isCensorship: Bool
    let videoURLStrings: [String]?
    let isInstrumental: Bool
    let isFreeForPlaylist: Bool
    let previewTypeValue: Int?
    let previewLimitTimes: Int?
    let isFollowAllowFreeDownload: Bool
    let releaseDateFans: Date?
    let featuring: String?
    let images: [Image]
    let audioFile: TrackAudioFile?
    let cleanAudioFile: TrackAudioFile?
    let artist: Artist
    let fansLiked: Int
    let fansDisliked: Int
//    let current_fan_listen: Any?
    let isReleasedForFans: Bool
    let writer: TrackWriter
    let backingTrack: TrackAudioFile?



    var previewType: PreviewType { return PreviewType(rawValue: self.previewTypeValue ?? 0) ?? .unknown }
    var isPlayable: Bool { return self.audioFile != nil }

    enum CodingKeys: String, CodingKey {
        case id
        case songId = "song_id"
        case name
        case radioInfo = "radio_info"
        case ownerId = "owner_id"
        case isCensorship = "is_censorship"
        case videoURLStrings = "video"
        case isInstrumental = "is_instrumental"
        case isFreeForPlaylist = "is_free_for_playlist"
        case previewTypeValue = "preview_type"
        case previewLimitTimes = "preview_limit_times"
        case isFollowAllowFreeDownload = "is_follow_allow_free_download"
        case releaseDateFans = "release_date_fans"
        case featuring
        case images
        case audioFile = "mp3_file"
        case cleanAudioFile = "clean_mp3_file"
        case artist
        case fansLiked = "fans_liked"
        case fansDisliked = "fans_disliked"
        case isReleasedForFans = "is_released_for_fans"
        case writer = "songwriter"
        case backingTrack = "backing_track"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)

        self.songId = try container.decode(Int.self, forKey: .songId)
        self.name = try container.decode(String.self, forKey: .name)
        self.radioInfo = try container.decode(String.self, forKey: .radioInfo)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.isCensorship = try container.decode(Bool.self, forKey: .isCensorship)

        self.videoURLStrings = try? container.decode([String].self, forKey: .videoURLStrings)
        self.isInstrumental = try container.decode(Bool.self, forKey: .isInstrumental)
        self.isFreeForPlaylist = try container.decode(Bool.self, forKey: .isFreeForPlaylist)
        self.previewTypeValue = try? container.decode(Int.self, forKey: .previewTypeValue)
        self.previewLimitTimes = try? container.decode(Int.self, forKey: .previewLimitTimes)
        self.isFollowAllowFreeDownload = try container.decode(Bool.self, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.releaseDateFans = try container.decodeAsDate(String.self, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        self.featuring = try? container.decode(String.self, forKey: .featuring)

        self.images = try container.decode([Image].self, forKey: .images)
        self.audioFile = try? container.decode(TrackAudioFile.self, forKey: .audioFile)
        self.cleanAudioFile = try? container.decode(TrackAudioFile.self, forKey: .cleanAudioFile)
        self.artist = try container.decode(Artist.self, forKey: .artist)

        self.fansLiked = try container.decode(Int.self, forKey: .fansLiked)
        self.fansDisliked = try container.decode(Int.self, forKey: .fansDisliked)
        self.isReleasedForFans = try container.decode(Bool.self, forKey: .isReleasedForFans)

        self.writer = try container.decode(TrackWriter.self, forKey: .writer)
        self.backingTrack = try? container.decode(TrackAudioFile.self, forKey: .backingTrack)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.songId, forKey: .songId)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.radioInfo, forKey: .radioInfo)
        try container.encode(self.ownerId, forKey: .ownerId)
        try container.encode(self.isCensorship, forKey: .isCensorship)
        try container.encode(self.videoURLStrings, forKey: .videoURLStrings)

        try container.encode(self.isInstrumental, forKey: .isInstrumental)
        try container.encode(self.isFreeForPlaylist, forKey: .isFreeForPlaylist)
        try container.encode(self.previewTypeValue, forKey: .previewTypeValue)
        try container.encode(self.previewLimitTimes, forKey: .previewLimitTimes)
        try container.encode(self.isFollowAllowFreeDownload, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.releaseDateFans, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        try container.encode(self.featuring, forKey: .featuring)
        try container.encode(self.images, forKey: .images)
        try container.encode(self.audioFile, forKey: .audioFile)
        try container.encode(self.cleanAudioFile, forKey: .cleanAudioFile)
        try container.encode(self.artist, forKey: .artist)

        try container.encode(self.fansLiked, forKey: .fansLiked)
        try container.encode(self.fansDisliked, forKey: .fansDisliked)
        try container.encode(self.isReleasedForFans, forKey: .isReleasedForFans)

        try container.encode(self.writer, forKey: .writer)
        try container.encode(self.backingTrack, forKey: .backingTrack)
    }
}

extension Track: Equatable {
    public static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Track: Hashable {
    public var hashValue: Int { return self.id }
}


