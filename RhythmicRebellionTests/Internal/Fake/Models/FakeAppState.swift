//
//  FakeAppState.swift
//
//  FakeAppState.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension AppState: Fakeble {

    static func fake() -> AppState {
        return AppState(player: PlayerState.fake(), user: User.fake())
    }
}
