//
//  ChangeTrackStateTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ChangeTrackStateTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testChangeTrackState() {
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        //Mock Requests
        let addonUrl = try! TrackRequest.addons(trackIds: [firstOrderedTrack.track.id]).asURLRequest().url!
        FakeRequests.Addons.registerAdvertisementAddon(with: addonUrl)
        
        let artistUrl = try! TrackRequest.artist(artistId: firstOrderedTrack.track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrl)
        
        expect(player.currentItem).to(beNil())
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: true))
        expect(player.currentItem).toNotEventually(beNil())
        
        expect(player.currentItem?.state.progress) == 0
        expect(player.currentItem?.state.isPlaying) == true
        
        let newState = TrackState(progress: 5, isPlaying: false, skipSeek: ())
        Dispatcher.dispatch(action: ChangeTrackState(trackState: newState))

        expect(player.currentItem?.state.progress) == 5
        expect(player.currentItem?.state.isPlaying) == false
    }
}

