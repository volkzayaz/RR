//
//  Track.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Track: Codable {

    let id: Int
    let songId: Int
    let name: String
    let radioInfo: String
    let ownerId: String
//    "is_censorship": false,
//    "video": [ "https:\/\/www.youtube.com\/watch?v=RYxtwYE7GPY" ],
//    "is_instrumental": false,
    let isFreeForPlaylist: Bool
//    "preview_type": null,
//    "preview_limit_times": null,
    let isFollowAllowFreeDownload: Bool
    let releaseDateFans: Date?
//    "featuring": null,
    let images: [Image]
    let audioFile: AudioFile?
    let cleanAudioFile: AudioFile?
    let artist: Artist
    let fansLiked: Int
    let fansDisliked: Int
//    "current_fan_listen": null,
    let isReleasedForFans: Bool
    let writer: TrackWriter
//    "backing_track": null

    var isPlayable: Bool { return self.audioFile != nil }

    enum CodingKeys: String, CodingKey {
        case id
        case songId = "song_id"
        case name
        case radioInfo = "radio_info"
        case ownerId = "owner_id"
        case isFreeForPlaylist = "is_free_for_playlist"
        case isFollowAllowFreeDownload = "is_follow_allow_free_download"
        case releaseDateFans = "release_date_fans"
        case images
        case audioFile = "mp3_file"
        case cleanAudioFile = "clean_mp3_file"
        case artist
        case fansLiked = "fans_liked"
        case fansDisliked = "fans_disliked"
        case isReleasedForFans = "is_released_for_fans"
        case writer = "songwriter"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.songId = try container.decode(Int.self, forKey: .songId)
        self.name = try container.decode(String.self, forKey: .name)
        self.radioInfo = try container.decode(String.self, forKey: .radioInfo)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.isFreeForPlaylist = try container.decode(Bool.self, forKey: .isFreeForPlaylist)
        self.isFollowAllowFreeDownload = try container.decode(Bool.self, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.releaseDateFans = try container.decodeAsDate(String.self, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        self.images = try container.decode([Image].self, forKey: .images)
        self.audioFile = try? container.decode(AudioFile.self, forKey: .audioFile)
        self.cleanAudioFile = try? container.decode(AudioFile.self, forKey: .cleanAudioFile)
        self.artist = try container.decode(Artist.self, forKey: .artist)

        self.fansLiked = try container.decode(Int.self, forKey: .fansLiked)
        self.fansDisliked = try container.decode(Int.self, forKey: .fansDisliked)
        self.isReleasedForFans = try container.decode(Bool.self, forKey: .isReleasedForFans)

        self.writer = try container.decode(TrackWriter.self, forKey: .writer)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.songId, forKey: .songId)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.radioInfo, forKey: .radioInfo)
        try container.encode(self.ownerId, forKey: .ownerId)
        try container.encode(self.isFreeForPlaylist, forKey: .isFreeForPlaylist)
        try container.encode(self.isFollowAllowFreeDownload, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.releaseDateFans, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        try container.encode(self.images, forKey: .images)
        try container.encode(self.audioFile, forKey: .audioFile)
        try container.encode(self.cleanAudioFile, forKey: .cleanAudioFile)
        try container.encode(self.artist, forKey: .artist)

        try container.encode(self.fansLiked, forKey: .fansLiked)
        try container.encode(self.fansDisliked, forKey: .fansDisliked)
        try container.encode(self.isReleasedForFans, forKey: .isReleasedForFans)

        try container.encode(self.writer, forKey: .writer)
    }
}




