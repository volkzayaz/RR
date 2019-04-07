//
//  TrackPreviewViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/18/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct TrackPreviewOptionViewModel {

    enum PreviewOptionType {
        case commigSoon
        case noPreview
        case freeForPlaylist
        case fullLimitTimes(Int)
        case limitSeconds(UInt)
        case authorizationNeeded
        
        init(with track: Track, user: User?, μSecondsPlayed: UInt64?) {
            
            guard track.isPlayable, let trackAudioFile = track.audioFile else { self = .commigSoon; return }
            guard track.isFreeForPlaylist == false else { self = .freeForPlaylist; return }
            guard let fanUser = user else { self = .authorizationNeeded; return; }
            guard fanUser.hasPurchase(for: track) == false else { self = .freeForPlaylist; return }
            guard (track.isFollowAllowFreeDownload && fanUser.isFollower(for: track.artist.id)) == false else { self = .freeForPlaylist; return }
            guard let t = track.previewType else { self = .noPreview; return }
            
            switch t {
            case .full:
                guard let previewLimitTimes = track.previewLimitTimes else { self = .freeForPlaylist; return }
                guard previewLimitTimes > 0 else { self = .fullLimitTimes(-1); return }
                
                guard let trackTotalPlayMSeconds = μSecondsPlayed else { self = .fullLimitTimes(previewLimitTimes); return }
                
                let trackMaxPlayMSeconds = UInt64(trackAudioFile.duration * 1000 * previewLimitTimes)
                guard trackMaxPlayMSeconds > trackTotalPlayMSeconds else { self = .fullLimitTimes(-1); return }
                
                let previewTimes = Int((trackMaxPlayMSeconds - trackTotalPlayMSeconds) / UInt64(trackAudioFile.duration * 1000))
                
                self = .fullLimitTimes(previewTimes)
                
            case .limit45: self = .limitSeconds(45)
            case .limit90: self = .limitSeconds(90)
                
            case .noPreview: self = .noPreview
            }
        }
    }
    
    let type: PreviewOptionType
    let textImageGenerator: TextImageGenerator
    
    init(type: PreviewOptionType,
         textImageGenerator: TextImageGenerator = .init(font: .systemFont(ofSize: 8))) {
        self.type = type
        self.textImageGenerator = textImageGenerator
    }
    
    var image: UIImage? {
        switch type {
        case .commigSoon: return nil
        case .noPreview: return UIImage(named: "DashMark")?.withRenderingMode(.alwaysTemplate)
        case .freeForPlaylist: return UIImage(named: "InfinityMark")?.withRenderingMode(.alwaysTemplate)
        case .fullLimitTimes(let limitTimes): return textImageGenerator.image(for: String(limitTimes >= 0 ? limitTimes : 0))
        case .limitSeconds(let seconds): return textImageGenerator.image(for: String(seconds) + "s")
        case .authorizationNeeded: return textImageGenerator.image(for: "!")
        }
    }

    var hintText: String? {
        switch type {
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
