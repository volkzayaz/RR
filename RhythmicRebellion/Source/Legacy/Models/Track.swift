//
//  Track.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public struct Track: Codable {

    public enum LikeStates: Int, Codable {
        case disliked = -1
        case none = 0
        case liked = 1

        var isLiked: Bool {
            switch self {
            case .liked: return true
            default: return false
            }
        }

        var isDisliked: Bool {
            switch self {
            case .disliked: return true
            default: return false
            }
        }
    }

    enum TrackPreviewType: Int, Codable {
        case noPreview = 1
        case full = 2
        case limit45 = 3
        case limit90 = 4
    }

    let id: Int
    let songId: Int
    let name: String
    let radioInfo: String
    let ownerId: String
    let isCensorship: Bool
    let videoURLStrings: [String]?
    let isInstrumental: Bool
    let isFreeForPlaylist: Bool
    let previewType: TrackPreviewType?
    let previewLimitTimes: Int?
    let isFollowAllowFreeDownload: Bool
    let releaseDateFans: Date?
    let featuring: String?
    let images: [Image]
    let audioFile: TrackAudioFile?
    let cleanAudioFile: DefaultAudioFile?
    let artist: Artist
//    let current_fan_listen: Any?
    let writer: TrackWriter
    let backingAudioFile: DefaultAudioFile?
    let price: Money?

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
        case previewType = "preview_type"
        case previewLimitTimes = "preview_limit_times"
        case isFollowAllowFreeDownload = "is_follow_allow_free_download"
        case releaseDateFans = "release_date_fans"
        case featuring
        case images
        case audioFile = "mp3_file"
        case cleanAudioFile = "clean_mp3_file"
        case artist
        case writer = "songwriter"
        case backingAudioFile = "backing_track"
        case price
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
        self.previewType = try? container.decode(TrackPreviewType.self, forKey: .previewType)
        self.previewLimitTimes = try? container.decode(Int.self, forKey: .previewLimitTimes)
        self.isFollowAllowFreeDownload = try container.decode(Bool.self, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.releaseDateFans = try container.decodeAsDate(String.self, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        self.featuring = try? container.decode(String.self, forKey: .featuring)

        self.images = try container.decode([Image].self, forKey: .images)
        self.audioFile = try? container.decode(TrackAudioFile.self, forKey: .audioFile)
        self.cleanAudioFile = try? container.decode(DefaultAudioFile.self, forKey: .cleanAudioFile)
        self.artist = try container.decode(Artist.self, forKey: .artist)

        self.writer = try container.decode(TrackWriter.self, forKey: .writer)
        self.backingAudioFile = try? container.decode(DefaultAudioFile.self, forKey: .backingAudioFile)

        if let priceValue = try container.decodeIfPresent(Decimal.self, forKey: .price) {
            self.price = Money(value: priceValue, currency: .USD)
        } else {
            self.price = nil
        }
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
        try container.encode(self.previewType, forKey: .previewType)
        try container.encode(self.previewLimitTimes, forKey: .previewLimitTimes)
        try container.encode(self.isFollowAllowFreeDownload, forKey: .isFollowAllowFreeDownload)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.releaseDateFans, forKey: .releaseDateFans, dateFormatter: dateTimeFormatter)

        try container.encode(self.featuring, forKey: .featuring)
        try container.encode(self.images, forKey: .images)
        try container.encode(self.audioFile, forKey: .audioFile)
        try container.encode(self.cleanAudioFile, forKey: .cleanAudioFile)
        try container.encode(self.artist, forKey: .artist)

        try container.encode(self.writer, forKey: .writer)
        try container.encode(self.backingAudioFile, forKey: .backingAudioFile)

        if let priceValue = self.price?.amount {
            try container.encode(priceValue, forKey: .price)
        }
    }

    func thumbnailURL(with orderedImageLinksTypes: [ImageLinkType]) -> URL? {

        for trackImage in self.images {
            guard let imageLink = trackImage.firstImageLink(from: orderedImageLinksTypes) else { continue }

            switch imageLink.path {
            case .url(let urlString):
                guard let imageLinkURL = URL(string: urlString) else { continue }
                return imageLinkURL
            default: continue
            }
        }

        return nil
    }

}

extension Track: Equatable {
    public static func == (lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Track: Hashable, CustomStringConvertible {
    public var hashValue: Int { return self.id }
    
    public var description: String {
        return name
    }
}
