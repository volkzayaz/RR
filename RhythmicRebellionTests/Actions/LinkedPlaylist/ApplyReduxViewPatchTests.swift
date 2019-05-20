//
//  ApplyReduxViewPatchTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ApplyReduxViewPatchTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testApplyReduxViewPatch() {
        
        let tracksToInsert = [t1, t2]
        expect(player.tracks.count) == 0
    
        let patch = player.tracks.insertPatch(tracks: tracksToInsert, after: nil)
        let reduxPatch = PlayerState.ReduxViewPatch(shouldFlush: true, patch: patch)
        expect(lastPatch).to(beNil())
        
        Dispatcher.dispatch(action: ApplyReduxViewPatch(viewPatch: reduxPatch))
        expect(lastPatch).toEventually(equal(reduxPatch))
        expect(orderedTracks.count) == tracksToInsert.count
    }
}

