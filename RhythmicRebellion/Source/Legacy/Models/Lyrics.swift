//
//  Lyrics.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/14/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct KaraokeInterval: Codable, Equatable {

    private let start: TimeInterval
    private let end: TimeInterval
    
    var range: ClosedRange<TimeInterval> {
        return ClosedRange(uncheckedBounds: (start, end))
    }
    
    let content: String
    
}

struct Karaoke: Codable, Equatable {

    let id: Int
    let trackId: Int
    let intervals: [KaraokeInterval]

    enum CodingKeys: String, CodingKey {
        case id
        case trackId = "record_id"
        case intervals
    }

}


public struct Lyrics: Codable, Equatable {

    let id: Int
    let lyrics: String
    let karaoke: Karaoke?

    enum CodingKeys: String, CodingKey {
        case id
        case lyrics
        case karaoke = "transcript"
    }
}
