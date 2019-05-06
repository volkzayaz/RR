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

@testable import RhythmicRebellion

class PlaylistDeleteTests: XCTestCase {
    
    var testObject = LinkedPlaylist()
    
    override func setUp() {
        testObject = LinkedPlaylist()
    }
    
    func testDeleteToEmpty() {
        
        let data = try! JsonReader.readData(withName: "playlist")
        let patch = TrackReduxViewPatch(jsonData: data)
        
        let playerState = PlayerState(tracks: LinkedPlaylist(),
                                      lastPatch: nil,
                                      currentItem: nil,
                                      isBlocked: false,
                                      lastChangeSignatureHash: WebSocketService.ownSignatureHash,
                                      config: PlayerConfig.fake())
        
        let state = AppState(player: playerState, user: User.fake())
    
        
        let x1 = Track.fake()
        
        //        _ = testObject.insert(tracks: [x1], after: nil)
        //        let tracks = testObject.orderedTracks
        //
        //        let res = testObject.delete(track: tracks[0])
        //
        //        expect(self.testObject.orderedTracks.count) == 0
        //
        //        expect(res.keys.count) == 1
        //        expect(res[tracks[0].orderHash]!).to(beNil())
        
    }
    
    func testDeleteFirst() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        #warning("Uncoment")
        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
        //        let tracks = testObject.orderedTracks
        //
        //        let res = testObject.delete(track: tracks[0])
        //
        //        expect(self.testObject.orderedTracks.count) == 2
        //
        //        expect(res.keys.count) == 2
        //        expect(res[tracks[0].orderHash]!).to(beNil())
        //        expect(res[tracks[1].orderHash]??[.previous]!).to(beNil())
        
    }
    
    func testDeleteLast() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        #warning("Uncoment")
        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
        //        let tracks = testObject.orderedTracks
        //
        //        let res = testObject.delete(track: tracks[2])
        //
        //        expect(self.testObject.orderedTracks.count) == 2
        //
        //        expect(res.keys.count) == 2
        //        expect(res[tracks[2].orderHash]!)         .to(beNil())
        //        expect(res[tracks[1].orderHash]??[.next]!).to(beNil())
        
    }
    
    func testDeleteMiddle() {
        
        let x1 = Track.fake()
        let x2 = Track.fake()
        let x3 = Track.fake()
        #warning("Uncoment")
        //        _ = testObject.insert(tracks: [x1, x2, x3], after: nil)
        //        let tracks = testObject.orderedTracks
        //
        //        let res = testObject.delete(track: tracks[1])
        //
        //        expect(self.testObject.orderedTracks.count) == 2
        //
        //        expect(res.keys.count) == 3
        //
        //        expect(res[tracks[0].orderHash]??[.next]     as? String) == tracks[2].orderHash
        //        expect(res[tracks[2].orderHash]??[.previous] as? String) == tracks[0].orderHash
        //
        //        expect(res[tracks[1].orderHash]!).to(beNil())
        
    }
    
    
}
