//
//  PlayerTrack.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/20/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum TrackStubReason {
    case noAudoFile(AudioFile?)
    case noPreview(AudioFile?)
    case containseExplicitMaterial(AudioFile?)

    var audioFile: AudioFile? {
        switch self {
        case .noAudoFile(let audioFile): return audioFile
        case .noPreview(let audioFile): return audioFile
        case .containseExplicitMaterial(let audioFile): return audioFile
        }
    }
}

class PlayerItem {

    let playlistItem: PlayerPlaylistItem
    let stubReason: TrackStubReason?
    let restrictedTime: TimeInterval?

    var trackId: TrackId {
        return TrackId(id: self.playlistItem.track.id, key: self.playlistItem.key, skipStat: stubReason == nil ? nil : true)
    }

    var isPlayable: Bool {
        guard let stubReason = stubReason else { return true }
        return stubReason.audioFile != nil
    }

    var stubAudioFile: AudioFile? { return self.stubReason?.audioFile }

    var trackMaxPlayMSeconds: UInt64? {
        guard let trackAudioFile = self.playlistItem.track.audioFile,
            let trackPreviewLimitTimes = self.playlistItem.track.previewLimitTimes,
            trackPreviewLimitTimes > 0 else { return nil }

        return UInt64(trackAudioFile.duration * 1000 * trackPreviewLimitTimes)
    }

    init(playlistItem: PlayerPlaylistItem, stubReason: TrackStubReason?, restrictedTime: TimeInterval?) {

        self.playlistItem = playlistItem
        self.stubReason = stubReason
        self.restrictedTime = restrictedTime
    }

}
