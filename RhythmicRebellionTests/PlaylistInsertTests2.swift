//
//  PlaylistInsert.swift
//  RhythmicRebellionTests
//
//  Created by Vlad Soroka on 2/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble

@testable import RhythmicRebellion

class PlaylistInsertTests2: XCTestCase {

    var testObject: LinkedPlaylist!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testObject = LinkedPlaylist()
    }

    func testSingleInitialInsert() {
        
        
        
        let x = Track.fake()
      
        
//        let res = testObject.insert(tracks: [x], after: nil)
//
//        let action = ApplyReduxViewPatch(res)
//
//        Dispacher.dispatch(action: action)
//
//        appState.player.linked
//
//        expect(res.keys.count) == 1
//        expect(res.first?.value?[.id] as? Int) == x.id
//        expect(res.first?.value?[.hash] as? String) == res.first?.key
//        expect(res.first?.value?[.next]!).to(beNil())
//        expect(res.first?.value?[.previous]!).to(beNil())
//
//        expect(self.testObject.orderedTracks.count) == 1
//        expect(self.testObject.orderedTracks.first?.track) == x
        
    }

    func testMultipleInitialInsert() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        #warning("Uncoment")
//        let res = testObject.insert(tracks: [x1, x2, x3], after: nil)
//
//        let tracks = testObject.orderedTracks
//
//        expect(tracks.count) == 3
//
//        expect(res[tracks[0].orderHash]??[.next] as? String) == tracks[1].orderHash
//        expect(res[tracks[0].orderHash]??[.previous]! as? String).to(beNil())
//
//        expect(res[tracks[1].orderHash]??[.next] as? String) == tracks[2].orderHash
//        expect(res[tracks[1].orderHash]??[.previous] as? String) == tracks[0].orderHash
//
//        expect(res[tracks[2].orderHash]??[.next]! as? String).to(beNil())
//        expect(res[tracks[2].orderHash]??[.previous] as? String) == tracks[1].orderHash
        
    }
    
    func testTwoConsequtiveInsert() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        #warning("Uncoment")
//        var res = testObject.insert(tracks: [x1], after: nil)
//        var tracks = testObject.orderedTracks
//
//        expect(tracks.count) == 1
//
//        expect(res[tracks[0].orderHash]??[.next]! as? String).to(beNil())
//        expect(res[tracks[0].orderHash]??[.previous]! as? String).to(beNil())
//
//        res = testObject.insert(tracks: [x2], after: tracks[0])
//        tracks = testObject.orderedTracks
//
//        expect(res[tracks[1].orderHash]??[.next]! as? String).to(beNil())
//        expect(res[tracks[1].orderHash]??[.previous] as? String) == tracks[0].orderHash
//
//        expect(res[tracks[0].orderHash]??.keys.count) == 1
//        expect(res[tracks[0].orderHash]??[.next] as? String) == tracks[1].orderHash
        
    }
    
    func testInsertToHead() {
     
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        
//        _ = testObject.insert(tracks: [x1, x2], after: nil)
//        let res = testObject.insert(tracks: [x3], after: nil)
//
//        let tracks = testObject.orderedTracks
//
//        expect(tracks.count) == 3
//
//        expect(res[tracks[0].orderHash]??[.id] as? Int) == x3.id
//
//        expect(res.keys.count) == 2
//
//        expect(res[tracks[0].orderHash]??.keys.count) == 4
//        expect(res[tracks[0].orderHash]??[.next] as? String) == tracks[1].orderHash
//        expect(res[tracks[0].orderHash]??[.previous]! as? String).to(beNil())
//
//        expect(res[tracks[1].orderHash]??.keys.count) == 1
//        expect(res[tracks[1].orderHash]??[.previous] as? String) == tracks[0].orderHash
        
    }
    
    func testInsertToTail() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        #warning("Uncoment")
//        _ = testObject.insert(tracks: [x1, x2], after: nil)
//        let res = testObject.insert(tracks: [x3], after: testObject.orderedTracks.last)
//
//        let tracks = testObject.orderedTracks
//
//        expect(tracks.count) == 3
//
//        expect(res[tracks[2].orderHash]??[.id] as? Int) == x3.id
//
//        expect(res.keys.count) == 2
//
//        expect(res[tracks[2].orderHash]??.keys.count) == 4
//        expect(res[tracks[2].orderHash]??[.previous] as? String) == tracks[1].orderHash
//        expect(res[tracks[2].orderHash]??[.next]! as? String).to(beNil())
//
//        expect(res[tracks[1].orderHash]??.keys.count) == 1
//        expect(res[tracks[1].orderHash]??[.next] as? String) == tracks[2].orderHash
        
    }
    
    func testMiddleInsert() {
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        
        #warning("Uncoment")
        
        //        _ = testObject.insert(tracks: [x1, x2], after: nil)
//        let res = testObject.insert(tracks: [x3], after: testObject.orderedTracks.first)
//
//        let tracks = testObject.orderedTracks
//
//        expect(tracks.count) == 3
//
//        expect(res.keys.count) == 3
//
//        expect(res[tracks[1].orderHash]??[.id] as? Int) == x3.id
//
//        expect(res[tracks[1].orderHash]??.keys.count) == 4
//        expect(res[tracks[1].orderHash]??[.previous] as? String) == tracks[0].orderHash
//        expect(res[tracks[1].orderHash]??[.next] as? String) == tracks[2].orderHash
//
//        expect(res[tracks[0].orderHash]??.keys.count) == 1
//        expect(res[tracks[0].orderHash]??[.next] as? String) == tracks[1].orderHash
//
//        expect(res[tracks[2].orderHash]??.keys.count) == 1
//        expect(res[tracks[2].orderHash]??[.previous] as? String) == tracks[1].orderHash
        
    }
    
}
