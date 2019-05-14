//
//  PrepareNewTrackTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/13/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa
import Mocker

@testable import Alamofire
@testable import RhythmicRebellion

class PrepareNewTrackTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testPrepareLyrics() {
        
        let tracks = [t1]
        
        Dispatcher.dispatch(action: StoreTracks(tracks: tracks))
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let addon = URL(string: "http://dev.api.rebellionretailsite.com/api/player/audio-add-ons-for-tracks")!
        Mock(url: addon, ignoreQuery: true, dataType: .json, statusCode: 200, data: [
            Mock.HTTPMethod.get : FakeData.addon
            ]).register()
        
        let artist = URL(string: "http://dev.api.rebellionretailsite.com/api/player/artist")!
        Mock(url: artist, ignoreQuery: true, dataType: .json, statusCode: 200, data: [
            Mock.HTTPMethod.get : FakeData.artist
            ]).register()
        
        let orderedTrack = orderedTracks[0]
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(appStateSlice.player.currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
}

