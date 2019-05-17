//
//  PrepareNewTrackByHashTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import Alamofire
@testable import RhythmicRebellion

class PrepareNewTrackByHashTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testPrepareNewTrackByHash() {
        let tracks = [t1]
        
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(lastPatch!.patch.count).toEventually(equal(tracks.count))
        
        let orderedTrack = orderedTracks[0]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [orderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: orderedTrack.track.artist.id)
        
        Dispatcher.dispatch(action: PrepareNewTrackByHash(orderHash: orderedTrack.orderHash))
        expect(currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
}


