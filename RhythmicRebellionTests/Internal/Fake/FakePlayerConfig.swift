//
//  FakePlayerConfig.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
@testable import RhythmicRebellion

extension PlayerConfig: Fakeble {
    static func fake() -> PlayerConfig {
        return PlayerConfig(explicitMaterialAudioFile: DefaultAudioFile.fake(),
                            noAudioFile: DefaultAudioFile.fake(),
                            noPreviewAudioFile: DefaultAudioFile.fake())
    }
}

extension DefaultAudioFile: Fakeble {
    static func fake() -> DefaultAudioFile {
        return DefaultAudioFile(duration: 100, urlString: "url")
    }
}
