//
//  FakeConfig.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension Config: Fakeble {
    
    static func fake() -> Config {
        return Config(hobbies: [], howHearList: [], languages: [])
    }
}
