//
//  PlaylistInsertTests.swift
//  RhythmicRebellionTests
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class PlaylistInsertTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        Dispatcher.dispatch(action: StoreTracks(tracks: Tracks.all))
    }
    
    func testNewState() {
        expect(lastPatch?.patch).to(beNil())
    }
    
    func testConsequtiveInsertTracks() {
        
        let tracks = [t1]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch?.patch.count).toEventually(equal(1))
        
        let v1 = lastPatch?.patch[orderedTracks[0].orderHash]!
        
        expect(v1![.id]       as? Int)   .to(equal(orderedTracks[0].track.id))
        expect(v1![.hash]     as? String).to(equal(orderedTracks[0].orderHash))
        expect(v1![.next]     as? String).to(beNil())
        expect(v1![.previous] as? String).to(beNil())
        
        let newTracks = [t2]
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: nil))
        expect(lastPatch?.patch.count).toEventually(equal(2))
        
        let v2 = lastPatch?.patch[orderedTracks[0].orderHash]!
        
        expect(v2![.id]       as? Int)    == orderedTracks[0].track.id
        expect(v2![.hash]     as? String) == orderedTracks[0].orderHash
        expect(v2![.next]     as? String) == orderedTracks[1].orderHash
        expect(v2![.previous] as? String).to(beNil())
        
        let v3 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        expect(v3.count) == 1
        expect(v3[.previous] as? String) == orderedTracks[0].orderHash
    }
    
    func testInitialInsertTracks() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!
        let v2 = lastPatch!.patch[orderedTracks[1].orderHash]!
        let v3 = lastPatch!.patch[orderedTracks[2].orderHash]!
        
        expect(v1![.id]       as? Int)    == orderedTracks[0].track.id
        expect(v1![.hash]     as? String) == orderedTracks[0].orderHash
        expect(v1![.next]     as? String) == orderedTracks[1].orderHash
        expect(v1![.previous] as? String).to(beNil())
        
        expect(v2![.id]       as? Int)    == orderedTracks[1].track.id
        expect(v2![.hash]     as? String) == orderedTracks[1].orderHash
        expect(v2![.next]     as? String) == orderedTracks[2].orderHash
        expect(v2![.previous] as? String) == orderedTracks[0].orderHash
        
        expect(v3![.id]       as? Int)    == orderedTracks[2].track.id
        expect(v3![.hash]     as? String) == orderedTracks[2].orderHash
        expect(v3![.next]     as? String).to(beNil())
        expect(v3![.previous] as? String) == orderedTracks[1].orderHash
    }
    
    func testInsertTracksToHead() {

        let tracks = [t1, t2]
        
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.orderedTracks.count).toEventually(equal(tracks.count))

        let newTracks = [t5, t6, t7]
        
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(newTracks.count + 1))
        
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!!
        let v2 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        let v3 = lastPatch!.patch[orderedTracks[2].orderHash]!!
        let v4 = lastPatch!.patch[orderedTracks[3].orderHash]!!

        expect(v1[.id]       as? Int)    == orderedTracks[0].track.id
        expect(v1[.hash]     as? String) == orderedTracks[0].orderHash
        expect(v1[.next]     as? String) == orderedTracks[1].orderHash
        expect(v1[.previous] as? String).to(beNil())

        expect(v2[.id]       as? Int)    == orderedTracks[1].track.id
        expect(v2[.hash]     as? String) == orderedTracks[1].orderHash
        expect(v2[.next]     as? String) == orderedTracks[2].orderHash
        expect(v2[.previous] as? String) == orderedTracks[0].orderHash

        expect(v3[.id]       as? Int)    == orderedTracks[2].track.id
        expect(v3[.hash]     as? String) == orderedTracks[2].orderHash
        expect(v3[.next]     as? String) == orderedTracks[3].orderHash
        expect(v3[.previous] as? String) == orderedTracks[1].orderHash
        
        expect(v4.count) == 1
        expect(v4[.previous] as? String) == orderedTracks[2].orderHash
        
        print(appStateSlice)
    }
    
    func testInsertToTail() {
        
        let tracks = [t1, t2]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let newTracks = [t5]
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: orderedTracks.last!))
        expect(lastPatch!.patch.count).toEventually(equal(2))
        
        let v1 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        let v2 = lastPatch!.patch[orderedTracks[2].orderHash]!!
        
        expect(v1.count) == 1
        expect(v1[.next]     as? String) == orderedTracks[2].orderHash
        expect(v1[.next]     as? String) == orderedTracks[2].orderHash
        
        expect(v2[.id]       as? Int)    == orderedTracks[2].track.id
        expect(v2[.hash]     as? String) == orderedTracks[2].orderHash
        expect(v2[.next]     as? String) .to(beNil())
        expect(v2[.previous] as? String) == orderedTracks[1].orderHash
    }
    
    func testMiddleInsert() {
        
        let tracks = [t1, t2, t3, t4]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let newTracks = [t5]
        
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: orderedTracks[1]))
        expect(lastPatch!.patch.count).toEventually(equal(3))
        
        let v1 = lastPatch!.patch[orderedTracks[1].orderHash]!!
        let v2 = lastPatch!.patch[orderedTracks[2].orderHash]!!
        let v3 = lastPatch!.patch[orderedTracks[3].orderHash]!!
        
        expect(v1.count) == 1
        expect(v1[.next]     as? String) == orderedTracks[2].orderHash
        
        expect(v2[.id]       as? Int)    == orderedTracks[2].track.id
        expect(v2[.hash]     as? String) == orderedTracks[2].orderHash
        expect(v2[.next]     as? String) == orderedTracks[3].orderHash
        expect(v2[.previous] as? String) == orderedTracks[1].orderHash
        
        expect(v3.count) == 1
        expect(v3[.previous] as? String) == orderedTracks[2].orderHash
    }
}
