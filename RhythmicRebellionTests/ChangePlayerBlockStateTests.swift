//
//  ChangePlayerBlockStateTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/13/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ChangePlayerBlockStateTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testChangePlayerBlockState() {
        Dispatcher.dispatch(action: ChangePlayerBlockState(isBlocked:true))
        expect(appStateSlice.player.isBlocked) == true
    }
}
