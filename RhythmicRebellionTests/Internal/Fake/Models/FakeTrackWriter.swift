//
//  FakeTrackWriter.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension TrackWriter: Fakeble {
    
    static func fake() -> TrackWriter {
        return TrackWriter(withID: fakeID(),
                           name: "TrackWriter",
                           urlString: "https://\(fakeString(components: 1))}.com")
    }
}
