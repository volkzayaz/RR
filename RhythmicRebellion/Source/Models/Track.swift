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
    let name: String
    let artist: Artist
    let audioFile: AudioFile?

    var isPlayable: Bool { return self.audioFile != nil }

////    songwriter: any;
//    let artist: String
//    let artist_id: String
//    let artist_url: String
//    let artist_follow: Bool
//    let record_like: Bool
//    let likes_count: Int
//    let albumCover: String?
////    video: any;
//    let image: String
////    images: any[];
//    let thumb: String
//    let lyrics: String;
//    let radio_info: String
//    let purchased: Bool
//    let mp3_file: AudioFile
//    let backing_track: AudioFile
//    let duration: Int?
//    let featuring: String
//    let is_censorship: Bool
////    current_fan_listen: { force_to_play: boolean };
//    let preview_type: Int?
//    let preview_limit_times: Int?
//    let is_free_for_playlist: Bool
//    let is_follow_allow_free_download: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artist
        case audioFile = "mp3_file"
    }
}
