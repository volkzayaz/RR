//
//  FakeDefaultAudioFile.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension DefaultAudioFile: Fakeble {
    static func fake() -> DefaultAudioFile {
        return DefaultAudioFile(duration: fakeNumber(bound: 120), urlString: "https://\(fakeString(components: 1)).com")
    }
}
