//
//  GetBackToPreviousItemTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class GetBackToPreviousItemTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        //Mocks Requests
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [firstOrderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: firstOrderedTrack.track.artist.id)
        
        //Prepare new track
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: true))
        expect(currentItem).toNotEventually(beNil())
    }
    
    func testGetBackToPreviousItem() {
        
        let newState = TrackState(progress: 5, isPlaying: false, skipSeek: ())
        Dispatcher.dispatch(action: ChangeTrackState(trackState: newState))
        Dispatcher.dispatch(action: GetBackToPreviousItem())
        
    }
}
