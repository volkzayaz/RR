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

        var isLiked: Bool { return self == .liked }
        var isDisliked: Bool { return self == .disliked }
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
    let isInstrumental: Bool
    let isFreeForPlaylist: Bool
    let previewType: TrackPreviewType?
    let previewLimitTimes: Int?
    let isFollowAllowFreeDownload: Bool
    let featuring: String?
    let images: [Image]
    let audioFile: TrackAudioFile?
    let cleanAudioFile: DefaultAudioFile?
    let artist: Artist
    let writer: TrackWriter
    let backingAudioFile: DefaultAudioFile?
    
    struct Video: Codable {
        let video_id: String
    }; let video: Video?
    
    var isPlayable: Bool { return self.audioFile != nil }

    enum CodingKeys: String, CodingKey {
        case id
        case songId = "song_id"
        case name
        case radioInfo = "radio_info"
        case ownerId = "owner_id"
        case isCensorship = "is_censorship"
        case video = "video_preview"
        case isInstrumental = "is_instrumental"
        case isFreeForPlaylist = "is_free_for_playlist"
        case previewType = "preview_type"
        case previewLimitTimes = "preview_limit_times"
        case isFollowAllowFreeDownload = "is_follow_allow_free_download"
        case featuring
        case images
        case audioFile = "mp3_file"
        case cleanAudioFile = "clean_mp3_file"
        case artist
        case writer = "songwriter"
        case backingAudioFile = "backing_track"
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

extension Track: Hashable {
    public var hashValue: Int { return self.id }
    
}

extension Track: Downloadable {
    
    var fileName: String {
        return "\(name).mp3"
    }

    public func asURL() throws -> URL {
        guard let x = audioFile?.urlString else {
            throw RRError.generic(message: "No URL")
        }
        
        return URL(string: x)!
    }
    
}
