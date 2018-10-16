//
//  AudioFileLocalItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/9/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation



enum TrackAudioFileLocalItemState {
    case unknown
    case downloaded(URL)
    case downloading(Int, Progress)
}

class TrackAudioFileLocalItem: Codable {

    let trackAudioFile: TrackAudioFile
    var state: TrackAudioFileLocalItemState

    enum CodingKeys: String, CodingKey {
        case trackAudioFile
        case localFileName
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
        } else if let localFileName = try container.decodeIfPresent(String.self, forKey: .localFileName) {
            self.state = .downloaded(ModelSupport.sharedInstance.documentDirectoryURL.appendingPathComponent(localFileName))
        } else {
            self.state = .unknown
        }
    }

    public func encode(to encoder: Encoder) throws {

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.trackAudioFile, forKey: .trackAudioFile)

        switch self.state {
        case .downloaded(let localURL):
            try container.encode(localURL.lastPathComponent, forKey: .localFileName)
        case .downloading(let taskId, _):
            try container.encode(taskId, forKey: .taskId)
        case .unknown: break
        }
    }
}
