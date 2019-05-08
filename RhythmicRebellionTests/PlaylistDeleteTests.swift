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
    
    let _appState = AppState.fake()
    
    override func setUp() {
        
        initActorStorage(x: ActorStorage(actors: [],
                                         x: FakeWebSocketService()))
        
        Dispatcher.state.accept(_appState)
        Dispatcher.beginSerialExecution()
    }
    
    func testDeleteToEmpty() {
        
        waitUntil { done in
            
            appState
                .drive(onNext: { (appState) in
                    
                    expect(true).to(beTrue())
                })
            
            let x = Track.fake()
            
            Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [x],
                                                                 style: .now))

            ////Proceeed verifing that AppState is correct
            
            
//            let data = try! JsonReader.readData(withName: "playlist")
//            let patch = TrackReduxViewPatch(jsonData: data)
//
//            let action = ApplyReduxViewPatch(viewPatch: .init(shouldFlush: patch.shouldFlush, patch: patch.data) )
//
////            Dispatcher.dispatch(action: AlienSignatureWrapper(action: action) )
////
//            Dispatcher.dispatch(action: AlienSignatureWrapper(action: StoreTracks(tracks:
//                [Track.fake(), Track.fake()]
//            )))
//
        }

        
        
        
        print(_appState.player.tracks)
        
//        let data = try! JsonReader.readData(withName: "playlist")
//        let patch = TrackReduxViewPatch(jsonData: data)
//
//        playerState = PlayerState(tracks: LinkedPlaylist(),
//                                      lastPatch: nil,
//                                      currentItem: nil,
//                                      isBlocked: false,
//                                      lastChangeSignatureHash: WebSocketService.ownSignatureHash,
//                                      config: PlayerConfig.fake())
        
    
//        _appState.asDriver().notNil()
        
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
