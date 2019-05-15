//
//  ChangeBlockStateTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/13/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ChangeBlockStateTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testChangeBlockState() {
        
        Dispatcher.dispatch(action: ChangePlayerBlockState(isBlocked:true))
        expect(appStateSlice.player.isBlocked).toEventually(equal(true))
        
        Dispatcher.dispatch(action: ChangePlayerBlockState(isBlocked:false))
        expect(appStateSlice.player.isBlocked).toEventually(equal(false))
    }
}
