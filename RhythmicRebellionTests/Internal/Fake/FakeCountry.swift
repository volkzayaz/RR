//
//  FakeCountry.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//


@testable import RhythmicRebellion

extension Country: Fakeble {
    
    static func fake() -> Country {
        return .init(withID: fakeNumber(bound: 1000),
                     code: "\(fakeNumber(bound: 190))",
                     name: "USA")
    }
}
