//
//  RhythmicRebellionTests.swift
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

class PlaylistDeleteTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(x: ActorStorage(actors: [], x: FakeWebSocketService()))
        Dispatcher.state.accept(AppState.fake())
        
    }
    
    func testInsertTrack() {
        
        let t1 = Track.fake(id: 1)
        let tracks = [t1]
        
        Dispatcher.dispatch(action: StoreTracks(tracks:tracks))
        expect(appStateSlice.player.tracks.trackDump.count).toEventually(equal(tracks.count))
        expect(appStateSlice.player.tracks.trackDump.first?.key).to(equal(t1.id))
        
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        let orderedTrack = appStateSlice.player.tracks.orderedTracks.first!
        expect(orderedTrack.track.id).toEventually(equal(t1.id))
        
        let lastPatch = appStateSlice.player.lastPatch
        expect(lastPatch).toNot(beNil())
        
        let data = lastPatch!.patch.first!
        expect(lastPatch!.patch.count).to(equal(tracks.count))
        expect(data.value![.id] as? Int).to(equal(t1.id))
        expect(data.value![.hash] as? String).to(equal(data.key))
        expect(data.value![.next] as? String).to(beNil())
        expect(data.value![.previous] as? String).to(beNil())
    }
    
    func testInsertTracks() {
        
        let t1 = Track.fake(id: 2)
        let t2 = Track.fake(id: 3)
        let tracks = [t1, t2]
        
        Dispatcher.dispatch(action: StoreTracks(tracks:tracks))
        expect(appStateSlice.player.tracks.trackDump.count).toEventually(equal(tracks.count))
        
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(appStateSlice.player.tracks.orderedTracks.count).toEventually(equal(tracks.count))
        
        let o1 = appStateSlice.player.tracks.orderedTracks[0]
        let o2 = appStateSlice.player.tracks.orderedTracks[1]
        expect(o1.track.id).toEventually(equal(t1.id))
        expect(o2.track.id).to(equal(t2.id))
        
    }
    
//    func testDeleteTracks() {
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
