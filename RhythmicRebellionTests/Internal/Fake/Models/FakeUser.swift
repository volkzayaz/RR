//
//  FakeUser.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension User: Fakeble {
    
    static func fake() -> User {
        return User(profile: UserProfile.fake(), wsToken: fakeID(length: 128))
    }
}
