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
        
        Dispatcher.dispatch(action: InsertTracks(tracks: Tracks.all, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(Tracks.all.count))
        
        let firstOrderedTrack = orderedTracks[0]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [firstOrderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: firstOrderedTrack.track.artist.id)
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: true))
        expect(currentItem).toNotEventually(beNil())
    }
    
    func testGetBackToPreviousItemWithResetProgress() {
        
        let newState = TrackState(progress: 5, isPlaying: false, skipSeek: ())
        Dispatcher.dispatch(action: ChangeTrackState(trackState: newState))
        expect(currentItem!.state.progress).toEventually(equal(5))
        
        Dispatcher.dispatch(action: GetBackToPreviousItem())
        expect(currentItem!.state.progress).toEventually(equal(0))
        
        let orderedTrack = orderedTracks[0]
        expect(currentItem!.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
    
    func testGetBackToPreviousItem() {

        let orderedTrack = orderedTracks[3]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [orderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: orderedTrack.track.artist.id)

        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: true))
        expect(currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
        
        let previousOrderedTrack = orderedTracks[2]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [previousOrderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: previousOrderedTrack.track.artist.id)
        
        let newState = TrackState(progress: 2, isPlaying: false, skipSeek: ())
        Dispatcher.dispatch(action: ChangeTrackState(trackState: newState))
        expect(currentItem!.state.progress).toEventually(equal(2))
        
        Dispatcher.dispatch(action: GetBackToPreviousItem())
        expect(currentItem!.activeTrackHash).toEventually(equal(previousOrderedTrack.orderHash))
        expect(currentItem!.state.progress).toEventually(equal(0))
    }
}
