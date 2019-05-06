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
        return User(withUserProfile: UserProfile.fake(),
                    wsToken: "cfb96a9ddcd69dbd658e6a418644621b70ec1f98535b5eba94a6842c010a1796")
    }
}
