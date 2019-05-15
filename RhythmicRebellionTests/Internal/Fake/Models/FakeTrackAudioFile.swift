//
//  TrackAudioFile.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/15/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension TrackAudioFile: Fakeble {
    static func fake() -> TrackAudioFile {
        return TrackAudioFile(id: fakeNumber(bound: 100),
                              bitrate: "128",
                              duration: 150,
                              urlString: "https://\(fakeString(components: 1)).com",
                              originalName: fakeString())
    }
}
