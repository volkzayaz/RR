//
//  AudioFile.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol AudioFile {
    var duration: Int { get }
    var urlString: String { get }
}


struct TrackAudioFile: AudioFile, Codable {
    let id: Int
    let bitrate: String
    let duration: Int
    let urlString: String
    let originalName: String

    enum CodingKeys: String, CodingKey {
        case id
        case bitrate
        case duration
        case urlString = "link"
        case originalName = "original_name"
    }
}

struct PlayerConfigAudioFile: AudioFile, Decodable {

    let duration: Int
    let urlString: String

    enum CodingKeys: String, CodingKey {
        case duration
        case urlString = "link"
    }

}
