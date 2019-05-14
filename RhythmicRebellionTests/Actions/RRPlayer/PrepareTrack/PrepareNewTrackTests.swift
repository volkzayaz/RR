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
        
        let orderedTrack = orderedTracks[0]
        
        let addonUrl = try! TrackRequest.addons(trackIds: [orderedTrack.track.id]).asURLRequest().url!
        FakeRequests.registerMockRequestAddons(with: addonUrl)
        
        let artistUrl = try! TrackRequest.artist(artistId: orderedTrack.track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrl)
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(appStateSlice.player.currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
}

