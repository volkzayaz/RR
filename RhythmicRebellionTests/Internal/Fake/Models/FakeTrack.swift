//
//  FakeTrack.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension Track: Fakeble {
    
    static func fake() -> Track {
        return Track.fake(id: fakeNumber(bound: 1000))
    }
    
    static func fake(id: Int, audioFile: TrackAudioFile? = TrackAudioFile.fake()) -> Track {
        
        return Track(id: id,
                     songId: fakeNumber(bound: 1000),
                     name: fakeString(),
                     radioInfo: fakeString(),
                     ownerId: fakeID(),
                     isCensorship: fakeBool(),
                     isInstrumental: fakeBool(),
                     isFreeForPlaylist: fakeBool(),
                     previewType: nil,
                     previewLimitTimes: nil,
                     isFollowAllowFreeDownload: fakeBool(),
                     featuring: nil,
                     images: [],
                     audioFile: audioFile,
                     cleanAudioFile: nil,
                     artist: Artist.fake(),
                     writer: TrackWriter.fake(),
                     backingAudioFile: DefaultAudioFile.fake(),
                     video: nil)
        
    }
}
