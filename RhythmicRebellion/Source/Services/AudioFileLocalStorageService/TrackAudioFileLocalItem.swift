//
//  AudioFileLocalItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/9/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation



enum TrackAudioFileLocalItemState {
    case downloaded(String)
    case downloading(Int, Progress)
}

class TrackAudioFileLocalItem: Codable {

    let trackAudioFile: TrackAudioFile
    var state: TrackAudioFileLocalItemState

    enum CodingKeys: String, CodingKey {
        case trackAudioFile
        case loacalURLString
        case taskId
    }

    init(trackAudioFile: TrackAudioFile, state: TrackAudioFileLocalItemState) {
        self.trackAudioFile = trackAudioFile
        self.state = state
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.trackAudioFile = try container.decode(TrackAudioFile.self, forKey: .trackAudioFile)

        if let taskId = try container.decodeIfPresent(Int.self, forKey: .taskId) {
            self.state = .downloading(taskId, Progress(totalUnitCount: 0))
        } else if let localURLString = try container.decodeIfPresent(String.self, forKey: .loacalURLString) {
            self.state = .downloaded(localURLString)
        } else {
            self.state = .downloaded("")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.trackAudioFile, forKey: .trackAudioFile)

        switch self.state {
        case .downloaded(let localURlString):
            try container.encode(localURlString, forKey: .loacalURLString)
        case .downloading(let taskId, _):
            try container.encode(taskId, forKey: .taskId)
        }
    }
}
