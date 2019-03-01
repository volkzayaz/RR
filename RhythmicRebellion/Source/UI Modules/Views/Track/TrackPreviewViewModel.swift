//
//  TrackPreviewViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/18/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct TrackPreviewOptionViewModel {

    struct Factory {

        func previewOptionType(for track: Track, user: User?) -> PreviewOptionType {
            guard track.isPlayable, let trackAudioFile = track.audioFile else { return .commigSoon }
            guard track.isFreeForPlaylist == false else { return .freeForPlaylist }
            guard let fanUser = user as? FanUser else { return .authorizationNeeded }
            guard fanUser.hasPurchase(for: track) == false else { return .freeForPlaylist }
            guard (track.isFollowAllowFreeDownload && fanUser.isFollower(for: track.artist.id)) == false else { return .freeForPlaylist }
            guard let t = track.previewType else {
                return .noPreview
            }

            switch t {
            case .full:
                guard let previewLimitTimes = track.previewLimitTimes else { return .freeForPlaylist }
                guard previewLimitTimes > 0 else { return .fullLimitTimes(-1) }
                
                let trackTotalPlayMSeconds: UInt64 = 0
                //guard let trackTotalPlayMSeconds = player?.totalPlayMSeconds(for: track.id) else { return .fullLimitTimes(previewLimitTimes) }

                let trackMaxPlayMSeconds = UInt64(trackAudioFile.duration * 1000 * previewLimitTimes)
                guard trackMaxPlayMSeconds > trackTotalPlayMSeconds else { return .fullLimitTimes(-1) }

                let previewTimes = Int((trackMaxPlayMSeconds - trackTotalPlayMSeconds) / UInt64(trackAudioFile.duration * 1000))

                return .fullLimitTimes(previewTimes)

            case .limit45: return .limitSeconds(45)
            case .limit90: return .limitSeconds(90)

            case .noPreview: return .noPreview
            
            }

        }

        func makeViewModel(track: Track, user: User?, textImageGenerator: TextImageGenerator) -> TrackPreviewOptionViewModel {

            let previewOptionType = self.previewOptionType(for: track, user: user)

            return TrackPreviewOptionViewModel(previewOptionType: previewOptionType, textImageGenerator: textImageGenerator)
        }
    }

    enum PreviewOptionType {
        case commigSoon
        case noPreview
        case freeForPlaylist
        case fullLimitTimes(Int)
        case limitSeconds(UInt)
        case authorizationNeeded
    }

    let textImageGenerator: TextImageGenerator
    let previewOptionType: PreviewOptionType


    init(previewOptionType: PreviewOptionType, textImageGenerator: TextImageGenerator) {
        self.previewOptionType = previewOptionType
        self.textImageGenerator = textImageGenerator
    }

    var image: UIImage? {
        switch previewOptionType {
        case .commigSoon: return nil
        case .noPreview: return UIImage(named: "DashMark")
        case .freeForPlaylist: return UIImage(named: "InfinityMark")
        case .fullLimitTimes(let limitTimes): return textImageGenerator.image(for: String(limitTimes >= 0 ? limitTimes : 0))
        case .limitSeconds(let seconds): return textImageGenerator.image(for: String(seconds) + "s")
        case .authorizationNeeded: return textImageGenerator.image(for: "!")
        }
    }

    var hintText: String? {
        switch previewOptionType {
        case .commigSoon: return nil
        case .noPreview: return NSLocalizedString("No previews available", comment: "No previews hint text")
        case .freeForPlaylist: return NSLocalizedString("Free add to playlist", comment: "Free add to playlist hint text")
        case .fullLimitTimes(let limitTimes):
            guard limitTimes >= 0 else { return NSLocalizedString("Buy this song to get full version", comment: "Buy this song to get full version hint text") }
            let limitTimesLocalizedTemplate = NSLocalizedString("%d full previews available", comment: "Limit times full previews available hint template")
            return String(format: limitTimesLocalizedTemplate, limitTimes)
        case .limitSeconds(let seconds):
            let firstSecondsLocalizedTemplate = NSLocalizedString("First %d seconds preview", comment: "First seconds preview hint template")
            return String(format: firstSecondsLocalizedTemplate, seconds)
        case .authorizationNeeded: return NSLocalizedString("Login to see previews available", comment: "Login to see previews available hint text")
        }
    }
}
