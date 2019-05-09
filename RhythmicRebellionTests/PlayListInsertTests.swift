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
import RxSwift

@testable import RhythmicRebellion

class PlaylistInsertTests: XCTestCase {
    
    let t1 = Track.fake(id: 1)
    let t2 = Track.fake(id: 2)
    let t3 = Track.fake(id: 3)
    let t4 = Track.fake(id: 3)
    let t5 = Track.fake(id: 4)
    let t6 = Track.fake(id: 5)
    let t7 = Track.fake(id: 2)
    let t8 = Track.fake(id: 6)
    
    ///1. apply StoreTracks once in setUp
    ///2. drop number of implicitelly unwrapped optionals
    
    override func setUp() {
        
        initActorStorage(x: ActorStorage(actors: [], x: FakeWebSocketService()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testNewState() {
        expect(appStateSlice.player.lastPatch).to(beNil())
    }
    
    func testConsequtiveInsertTracks() {
        
        let tracks = [t1]
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(1))
        
        let lastPatch = appStateSlice.player.lastPatch
        let orderedTracks = appStateSlice.player.tracks.orderedTracks
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!
        
        expect(v1![.id]       as? Int)   .to(equal(orderedTracks[0].track.id))
        expect(v1![.hash]     as? String).to(equal(orderedTracks[0].orderHash))
        expect(v1![.next]     as? String).to(beNil())
        expect(v1![.previous] as? String).to(beNil())
        
        let newTracks = [t2]
        Dispatcher.dispatch(action: StoreTracks(tracks: newTracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(2))
        
        let newPatch = appStateSlice.player.lastPatch
        let newOrderedTracks = appStateSlice.player.tracks.orderedTracks
        
        let v2 = newPatch!.patch[newOrderedTracks[0].orderHash]!
        
        expect(v2![.id]       as? Int)   .to(equal(newOrderedTracks[0].track.id))
        expect(v2![.hash]     as? String).to(equal(newOrderedTracks[0].orderHash))
        expect(v2![.next]     as? String).to(equal(newOrderedTracks[1].orderHash))
        expect(v2![.previous] as? String).to(beNil())
        
        ////we also need to make sure there is exactly ONE entry int the patch in this case
        ////we need to make sure no "id", "hash" or "next" is present in the patch
        ////expect(v3!.count) == 1
        let v3 = newPatch!.patch[newOrderedTracks[1].orderHash]!
        expect(v3![.id]       as? Int)   .to(beNil())
        expect(v3![.hash]     as? String).to(beNil())
        expect(v3![.next]     as? String).to(beNil())
        expect(v3![.previous] as? String).to(equal(newOrderedTracks[0].orderHash))
    }
    
    func testInitialInsertTracks() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let lastPatch = appStateSlice.player.lastPatch
        let orderedTracks = appStateSlice.player.tracks.orderedTracks;
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!
        let v2 = lastPatch!.patch[orderedTracks[1].orderHash]!
        let v3 = lastPatch!.patch[orderedTracks[2].orderHash]!
        
        expect(v1![.id]       as? Int)   .to(equal(orderedTracks[0].track.id))
        expect(v1![.hash]     as? String).to(equal(orderedTracks[0].orderHash))
        expect(v1![.next]     as? String).to(equal(orderedTracks[1].orderHash))
        expect(v1![.previous] as? String).to(beNil())
        
        expect(v2![.id]       as? Int)   .to(equal(orderedTracks[1].track.id))
        expect(v2![.hash]     as? String).to(equal(orderedTracks[1].orderHash))
        expect(v2![.next]     as? String).to(equal(orderedTracks[2].orderHash))
        expect(v2![.previous] as? String).to(equal(orderedTracks[0].orderHash))
        
        expect(v3![.id]       as? Int)   .to(equal(orderedTracks[2].track.id))
        expect(v3![.hash]     as? String).to(equal(orderedTracks[2].orderHash))
        expect(v3![.next]     as? String).to(beNil())
        expect(v3![.previous] as? String).to(equal(orderedTracks[1].orderHash))
    }
    
    func testInsertTracksToHead() {

        let tracks = [t1, t2]
        
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.tracks.orderedTracks.count).toEventually(equal(tracks.count))

        let newTracks = [t5, t6, t7]
        
        Dispatcher.dispatch(action: StoreTracks(tracks: newTracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(newTracks.count + 1))
        
        let lastPatch = appStateSlice.player.lastPatch
        let orderedTracks = appStateSlice.player.tracks.orderedTracks;
        
        let v1 = lastPatch!.patch[orderedTracks[0].orderHash]!
        let v2 = lastPatch!.patch[orderedTracks[1].orderHash]!
        let v3 = lastPatch!.patch[orderedTracks[2].orderHash]!
        let v4 = lastPatch!.patch[orderedTracks[3].orderHash]!

        expect(v1![.id]       as? Int)   .to(equal(orderedTracks[0].track.id))
        expect(v1![.hash]     as? String).to(equal(orderedTracks[0].orderHash))
        expect(v1![.next]     as? String).to(equal(orderedTracks[1].orderHash))
        expect(v1![.previous] as? String).to(beNil())

        expect(v2![.id]       as? Int)   .to(equal(orderedTracks[1].track.id))
        expect(v2![.hash]     as? String).to(equal(orderedTracks[1].orderHash))
        expect(v2![.next]     as? String).to(equal(orderedTracks[2].orderHash))
        expect(v2![.previous] as? String).to(equal(orderedTracks[0].orderHash))

        expect(v3![.id]       as? Int)   .to(equal(orderedTracks[2].track.id))
        expect(v3![.hash]     as? String).to(equal(orderedTracks[2].orderHash))
        expect(v3![.next]     as? String).to(equal(orderedTracks[3].orderHash))
        expect(v3![.previous] as? String).to(equal(orderedTracks[1].orderHash))
        
        ////we also need to make sure there is exactly ONE entry int the patch in this case
        ////we need to make sure no "id", "hash" or "next" is present in the patch
        ////expect(v3!.count) == 1
        //Diff only previous
        expect(v4![.id]       as? Int)   .to(beNil())
        expect(v4![.hash]     as? String).to(beNil())
        expect(v4![.next]     as? String).to(beNil())
        expect(v4![.previous] as? String).to(equal(orderedTracks[2].orderHash))
    }
    
    func testInsertToTail() {
        
        let tracks = [t1, t2]
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let orderedTracks = appStateSlice.player.tracks.orderedTracks;
        
        let newTracks = [t5]
        Dispatcher.dispatch(action: StoreTracks(tracks: newTracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: orderedTracks.last!))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(2))
        
        let newOrderedTracks = appStateSlice.player.tracks.orderedTracks;
        let lastPatch = appStateSlice.player.lastPatch
        let v1 = lastPatch!.patch[newOrderedTracks[1].orderHash]!
        let v2 = lastPatch!.patch[newOrderedTracks[2].orderHash]!
        
        ////we also need to make sure there is exactly ONE entry int the patch in this case
        ////we need to make sure no "id", "hash" or "next" is present in the patch
        ////expect(v3!.count) == 1
        expect(v1![.id]       as? Int)   .to(beNil())
        expect(v1![.hash]     as? String).to(beNil())
        expect(v1![.next]     as? String).to(equal(newOrderedTracks[2].orderHash))
        expect(v1![.previous] as? String).to(beNil())
        
        expect(v2![.id]       as? Int)   .to(equal(newOrderedTracks[2].track.id))
        expect(v2![.hash]     as? String).to(equal(newOrderedTracks[2].orderHash))
        expect(v2![.next]     as? String).to(beNil())
        expect(v2![.previous] as? String).to(equal(newOrderedTracks[1].orderHash))
    }
    
    func testMiddleInsert() {
        
        let tracks = [t1, t2, t3, t4]
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let newTracks = [t5]
        let orderedTracks = appStateSlice.player.tracks.orderedTracks;
        
        Dispatcher.dispatch(action: StoreTracks(tracks: newTracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: newTracks, afterTrack: orderedTracks[1]))
        expect(appStateSlice.player.lastPatch!.patch.count).toEventually(equal(3))
        
        let lastPatch = appStateSlice.player.lastPatch
        let newOrderedTracks = appStateSlice.player.tracks.orderedTracks;
        
        let v1 = lastPatch!.patch[newOrderedTracks[1].orderHash]!
        let v2 = lastPatch!.patch[newOrderedTracks[2].orderHash]!
        let v3 = lastPatch!.patch[newOrderedTracks[3].orderHash]!
        
        ////we also need to make sure there is exactly ONE entry int the patch in this case
        ////we need to make sure no "id", "hash" or "next" is present in the patch
        ////expect(v1!.count) == 1
        expect(v1![.id]       as? Int)   .to(beNil())
        expect(v1![.hash]     as? String).to(beNil())
        expect(v1![.next]     as? String).to(equal(newOrderedTracks[2].orderHash))
        expect(v1![.previous] as? String).to(beNil())
        
        expect(v2![.id]       as? Int)   .to(equal(newOrderedTracks[2].track.id))
        expect(v2![.hash]     as? String).to(equal(newOrderedTracks[2].orderHash))
        expect(v2![.next]     as? String).to(equal(newOrderedTracks[3].orderHash))
        expect(v2![.previous] as? String).to(equal(newOrderedTracks[1].orderHash))
        
        ////we also need to make sure there is exactly ONE entry int the patch in this case
        ////we need to make sure no "id", "hash" or "next" is present in the patch
        ////expect(v3!.count) == 1
        expect(v3![.id]       as? Int)   .to(beNil())
        expect(v3![.hash]     as? String).to(beNil())
        expect(v3![.next]     as? String).to(beNil())
        expect(v3![.previous] as? String).to(equal(newOrderedTracks[2].orderHash))
    }
    
}
