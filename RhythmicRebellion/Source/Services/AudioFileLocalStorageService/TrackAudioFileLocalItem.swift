//
//  AudioFileLocalItem.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/9/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol TrackAudioFileDownloadingInfoWatcher: class {
    func trackAudioFileDownloadingInfoObserver(_ trackAudioFileDownloadingInfo: TrackAudioFileDownloadingInfo, didUpdate progress: Progress)
}

extension TrackAudioFileDownloadingInfoWatcher {
    func trackAudioFileDownloadingInfoObserver(_ trackAudioFileDownloadingInfo: TrackAudioFileDownloadingInfo, didUpdate progress: Progress) { }
}

class TrackAudioFileDownloadingInfo: Watchable {

    typealias WatchType = TrackAudioFileDownloadingInfoWatcher
    let watchersContainer = WatchersContainer<WatchType>()

    let taskIdentifier: Int
    let progress: Progress

    init(with taskIdentifier: Int, progress: Progress = Progress(totalUnitCount: 0)) {
        self.taskIdentifier = taskIdentifier
        self.progress = progress
    }

    func updateProgress(with totalUnitCount: Int64, completedUnitCount: Int64) {
        self.progress.totalUnitCount = totalUnitCount
        self.progress.completedUnitCount = completedUnitCount

        DispatchQueue.main.async {
            self.watchersContainer.invoke { (observer) in
                observer.trackAudioFileDownloadingInfoObserver(self, didUpdate: self.progress)
            }
        }
    }
}

class TrackAudioFileLocalItem: Codable {

    enum State {
        case unknown
        case downloaded(URL)
        case downloading(TrackAudioFileDownloadingInfo)
    }

    let trackAudioFile: TrackAudioFile
    var state: State

    enum CodingKeys: String, CodingKey {
        case trackAudioFile
        case localFileName
        case taskId
    }

    init(trackAudioFile: TrackAudioFile, state: State) {
        self.trackAudioFile = trackAudioFile
        self.state = state
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.trackAudioFile = try container.decode(TrackAudioFile.self, forKey: .trackAudioFile)

        if let taskId = try container.decodeIfPresent(Int.self, forKey: .taskId) {
            self.state = .downloading(TrackAudioFileDownloadingInfo(with: taskId))
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
        case .downloading(let downloadingInfo):
            try container.encode(downloadingInfo.taskIdentifier, forKey: .taskId)
        case .unknown: break
        }
    }
}
