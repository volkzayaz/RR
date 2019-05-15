//
//  UpdateTrackPrviewTimesTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class UpdateTrackPrviewTimesTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testUpdateTrackPrviewTimes() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: UpdateTrackPrviewTimes(newPreviewTimes: [t1.id: 100]))
    }
}

