//
//  ChangeTrackStateTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ChangeTrackStateTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testChangeTrackState() {
//        Dispatcher.dispatch(action: ChangeTrackState())
    }
}

