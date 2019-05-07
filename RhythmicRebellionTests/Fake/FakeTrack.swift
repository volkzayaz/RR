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
    
    static func fake(id: Int) -> Track {
        return Track(id: id,
                     songId: fakeNumber(bound: 1000),
                     name: fakeString(),
                     radioInfo: fakeString(),
                     ownerId: fakeID(),
                     artist: Artist.fake(),
                     writer: TrackWriter.fake(),
                     images: [Image]())
        
    }
}
