//
//  FakeLinkedPlaylist.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension LinkedPlaylist: Fakeble {
    
    static func fake() -> LinkedPlaylist {
        return LinkedPlaylist()
    }
}
