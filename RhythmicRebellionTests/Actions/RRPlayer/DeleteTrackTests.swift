//
//  DeleteTrackTests.swift
//  RhythmicRebellionTests
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble

@testable import RhythmicRebellion

class DeleteTrackTests: XCTestCase {

    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        Dispatcher.dispatch(action: StoreTracks(tracks: Tracks.all))
    }
    
    func testDeleteTrackToEmpty() {
        
        let tracks = [t1]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        Dispatcher.dispatch(action: DeleteTrack(track: orderedTracks[0]))
        expect(lastPatch!.patch.count).toEventually(equal(0))
        expect(lastPatch!.shouldFlush) == true
        expect(orderedTracks.count) == 0
    }
    
    func testDeleteFirstTrack() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let orderedTrackToRemove = orderedTracks[0]
        Dispatcher.dispatch(action: DeleteTrack(track: orderedTrackToRemove))
        expect(lastPatch!.patch.count) == 2
        expect(orderedTracks.count) == 2
        
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!!
        let v2 = lastPatch!.patch[orderedTrackToRemove.orderHash]
        
        expect(v1.count) == 1
        expect(v1[.previous] as Any?).notTo(beNil())
        expect(v2).notTo(beNil())
    }
    
    func testDeleteLastTrack() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        
        let orderedTrackToRemove = orderedTracks.last!
        Dispatcher.dispatch(action: DeleteTrack(track: orderedTrackToRemove))
        expect(lastPatch!.patch.count) == 2
        expect(orderedTracks.count) == 2
        
        let v1 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        let v2 = lastPatch!.patch[orderedTrackToRemove.orderHash]
        
        expect(v1.count) == 1
        expect(v1[.next] as Any?).notTo(beNil())
        expect(v2).notTo(beNil())
    }
    
    func testDeleteMiddleTrack() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        
        let orderedTrackToRemove = orderedTracks[1]
        Dispatcher.dispatch(action: DeleteTrack(track: orderedTrackToRemove))
        expect(lastPatch!.patch.count) == 3
        expect(orderedTracks.count) == 2
        
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!!
        let v2 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        let v3 = lastPatch!.patch[orderedTrackToRemove.orderHash]
        
        expect(v1.count) == 1
        expect(v1[.next] as? String) == orderedTracks[1].orderHash
        
        expect(v2.count) == 1
        expect(v2[.previous] as? String) == orderedTracks[0].orderHash
        
        expect(v3).notTo(beNil())
    }
}

