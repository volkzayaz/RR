//
//  FakeTrackWriter.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

@testable import RhythmicRebellion

extension TrackWriter: Fakeble {
    
    static func fake() -> TrackWriter {
        return TrackWriter(withID: fakeID(), name: "TrackWriter", urlString: "https://url.com")
    }
}
