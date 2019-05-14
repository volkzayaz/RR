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
        return Artist(withId: "4104abcd-b6a8-421f-8b54-d09dcc53c16b", name: "Artist")
    }
}
