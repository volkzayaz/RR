//
//  FakeArtist.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension Artist: Fakeble {
    
    static func fake() -> Artist {
        return Artist(withId: fakeID(), name: "Artist")
    }
}
