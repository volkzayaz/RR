//
//  TrackPreviewViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 10/18/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct PreviewOptions {
    
    enum Badge {
        case seconds45
        case seconds90
        case times(Int)
        case lock
        case exclaimation
    }; let badge: Badge?
    
    enum AudioRestriction {
        case seconds45
        case seconds90
        case noPreview
    }; let audioRestriction: AudioRestriction?
    
    init(with track: Track, user: User, μSecondsPlayed: UInt64? = nil) {
        
/*
  trackPreview |    45/guest  |   90/guest      |  times/guest |       noPreview/guest             |   full/guest
               |              |                 |              |                                   |
  badge        |    45sec / ! |   90sec / !     |   X / !      |             🔒 / !                |   empty / empty
               |              |                 |              |                                   |
  audio        |  45sec/45sec |   90sec / 45sec | X -> / 45sec | "noPreview".mp3 / "noPreview".mp3 |   full  /  full
 restriction
*/
        
        guard let t = track.previewType else {
            badge = nil; audioRestriction = nil
            return
        }
        
        guard user.isGuest == false else {
            badge = .exclaimation
            
            if case .noPreview = t { audioRestriction = .noPreview }
            else                   { audioRestriction = .seconds45 }
            
            return
        }
        
        ///1. user logged in
        ///2.1 user has purchased track
        ///    OR
        ///2.2 user followed track's artist AND Artist allows preview on following
        if user.hasPurchase(for: track) ||
           (track.isFollowAllowFreeDownload && user.isFollower(for: track.artist.id)) {
            badge = nil
            audioRestriction = nil
            return
        }
        
        switch t {
        case .limit45:
            badge = .seconds45
            audioRestriction = .seconds45
            
        case .limit90:
            badge = .seconds90
            audioRestriction = .seconds90
            
        case .full:
            
            guard let audioDuration = track.audioFile?.duration,
                  let times = track.previewLimitTimes,
                  let μSecondsEllapsed = μSecondsPlayed else { badge = nil; audioRestriction = nil; return; }
            
            let μSecondsAllowed = UInt64(audioDuration * 1000 * times)
            let previewTimes = Int((μSecondsAllowed - μSecondsEllapsed) / UInt64(audioDuration * 1000))
            
            badge            = previewTimes > 0 ? .times(previewTimes) : .seconds45
            audioRestriction = previewTimes > 0 ? nil : .seconds45
            
        case .noPreview:
            
            badge = .lock
            audioRestriction = .noPreview
            
        }
    
    }
}

