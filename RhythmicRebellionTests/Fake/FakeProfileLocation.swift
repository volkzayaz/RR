//
//  FakeProfileLocation.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension ProfileLocation: Fakeble {
    
    static func fake() -> ProfileLocation {
        return ProfileLocation(country: Country(withID: 10, code: "60", name: "USA"))
    }
}


