//
//  TrackItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit


struct TrackViewModel: TrackTableViewCellViewModel {

    var id: String { return String(track.id) }

    var title: String { return track.name }
    var description: String { return track.artist.name }

    var isPlayable: Bool { return track.isPlayable }

    var previewOptionImage: UIImage? { return previewOptionViewModel.image }
    var previewOptionHintText: String? { return previewOptionViewModel.hintText }

    var censorshipHintText: String? {
        guard self.isCensorship == true else { return nil }
        return NSLocalizedString("Contains explisit material", comment: "Contains explisit material hint text")
    }

    var downloadHintText: String?

    let track: Track

    var isCurrentInPlayer: Bool
    var isPlaying: Bool

    var isCensorship: Bool
    
    let previewOptionViewModel: TrackPreviewOptionViewModel

    var downloadState: TrackDownloadState?

    var isLockedForActions: Bool
}


extension TrackViewModel {

    init(track: Track, user: User?, player: Player?, audioFileLocalStorageService: AudioFileLocalStorageService?, textImageGenerator: TextImageGenerator, isCurrentInPlayer: Bool, isLockedForActions: Bool) {

        self.track = track
        self.isCurrentInPlayer = isCurrentInPlayer
        self.isPlaying = isCurrentInPlayer && (player?.isPlaying ?? false)

        self.isCensorship = user?.isCensorshipTrack(track) ?? track.isCensorship

        self.previewOptionViewModel = TrackPreviewOptionViewModel.Factory().makeViewModel(track: track,
                                                                                          user: user,
                                                                                          player: player,
                                                                                          textImageGenerator: textImageGenerator)

        let userHasPurchase = user?.hasPurchase(for: track) ?? false
        if track.isFollowAllowFreeDownload || userHasPurchase {

            self.downloadState = .disable
            if userHasPurchase || user?.isFollower(for: track.artist.id) ?? false {
                self.downloadState = .ready
                if let audioFile = track.audioFile, let state = audioFileLocalStorageService?.state(for: audioFile) {
                    switch state {
                    case .downloaded( _ ): self.downloadState = .downloaded
                    case .downloading(_, let progress): self.downloadState = .downloading(progress)
                    case .unknown: break
                    }
                }
            }

            if let downloadState = self.downloadState {
                switch downloadState {
                case .disable:
                    if user?.isGuest ?? true {
                        self.downloadHintText = NSLocalizedString("Free download for fans", comment: "Free download for fans hint text")
                    } else {
                        self.downloadHintText = NSLocalizedString("Free download for followers", comment: "Free download for followers hint text")
                    }
                default: break
                }
            }
        }

        self.isLockedForActions = isLockedForActions
    }
}
