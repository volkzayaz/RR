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
        
        let lastPatch = appStateSlice.player.lastPatch
//        let v1 = lastPatch!.patch[orderedTracks[orderedTracks.count - 1].orderHash]!
//        let v2 = lastPatch!.patch[orderedTracks[orderedTracks.count - 2].orderHash]!
        
//        let v2 = lastPatch!.patch[newOrderedTracks[1].orderHash]!
    }
//        let orrderedTrack = appStateSlice.player.tracks.orderedTracks.first!
//        Dispatcher.dispatch(action: DeleteTrack(track: orrderedTrack))
//        expect(appStateSlice.player.tracks.orderedTracks.count).toEventually(equal(0))
//        
//        //        expect(res.keys.count) == 1
//        //        expect(res.first?.value?[.id] as? Int) == x.id
//        //        expect(res.first?.value?[.hash] as? String) == res.first?.key
//        //        expect(res.first?.value?[.next]!).to(beNil())
//        //        expect(res.first?.value?[.previous]!).to(beNil())
//        
//        
//        
//        //        _ = testObject.insert(tracks: [x1], after: nil)
//        //        let tracks = testObject.orderedTracks
//        //
//        //        let res = testObject.delete(track: tracks[0])
//        //
//        //        expect(self.testObject.orderedTracks.count) == 0
//        //
//        //        expect(res.keys.count) == 1
//        //        expect(res[tracks[0].orderHash]!).to(beNil())
//        
//    }
    
//    func testDeleteFirst() {
//        
//        let data = try! JsonReader.readData(withName: "playlist")
//        let patch = TrackReduxViewPatch(jsonData: data)
//        let action = ApplyReduxViewPatch(viewPatch: .init(shouldFlush: patch.shouldFlush, patch: patch.data) )
//        
//        Dispatcher.dispatch(action: action)
//        
//        expect(appStateSlice.player.tracks.count).toEventually(equal(patch.data.count))
//        
//        let x1 = Track.fake()
//        let x2 = Track.fake()
//        let x3 = Track.fake()
//        #warning("Uncoment")
//        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
//        //        let tracks = testObject.orderedTracks
//        //
//        //        let res = testObject.delete(track: tracks[0])
//        //
//        //        expect(self.testObject.orderedTracks.count) == 2
//        //
//        //        expect(res.keys.count) == 2
//        //        expect(res[tracks[0].orderHash]!).to(beNil())
//        //        expect(res[tracks[1].orderHash]??[.previous]!).to(beNil())
//        
//    }
//    
//    func testDeleteLast() {
//        
//        let x1 = Track.fake()
//        let x2 = Track.fake()
//        let x3 = Track.fake()
//        #warning("Uncoment")
//        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
//        //        let tracks = testObject.orderedTracks
//        //
//        //        let res = testObject.delete(track: tracks[2])
//        //
//        //        expect(self.testObject.orderedTracks.count) == 2
//        //
//        //        expect(res.keys.count) == 2
//        //        expect(res[tracks[2].orderHash]!)         .to(beNil())
//        //        expect(res[tracks[1].orderHash]??[.next]!).to(beNil())
//        
//    }
//    
//    func testDeleteMiddle() {
//        
//        let x1 = Track.fake()
//        let x2 = Track.fake()
//        let x3 = Track.fake()
//        #warning("Uncoment")
//        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
//        //        let tracks = testObject.orderedTracks
//        //
//        //        let res = testObject.delete(track: tracks[1])
//        //
//        //        expect(self.testObject.orderedTracks.count) == 2
//        //
//        //        expect(res.keys.count) == 3
//        //
//        //        expect(res[tracks[0].orderHash]??[.next]     as? String) == tracks[2].orderHash
//        //        expect(res[tracks[2].orderHash]??[.previous] as? String) == tracks[0].orderHash
//        //
//        //        expect(res[tracks[1].orderHash]!).to(beNil())
//        
//    }
//    
    
}
