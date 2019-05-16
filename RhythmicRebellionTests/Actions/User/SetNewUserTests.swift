//
//  SetNewUserTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/12/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class SetNewUserTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testNewUser() {
        let newUser = User.fake()
        Dispatcher.dispatch(action: SetNewUser(user: newUser))
        expect(appStateSlice.user).toEventually(equal(newUser))
        expect(SettingsStore.lastSignedUserEmail.value) == newUser.profile?.email
    }
}
