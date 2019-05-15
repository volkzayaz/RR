//
//  AudioPlayerActionsTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class AudioPlayerActionsTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func prepareTrack() {
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        //Mock Requests
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [firstOrderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: firstOrderedTrack.track.artist.id)
        //Prepare new track
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: false))
        expect(currentItem).toNotEventually(beNil())
    }
    
    func testPlay() {
        
        prepareTrack()
        
        Dispatcher.dispatch(action: AudioPlayer.Play())
        expect(currentItem!.state.isPlaying).toEventually(equal(true))
        
        let firstOrderedTrack = orderedTracks[0]
        expect(currentItem!.activeTrackHash) == firstOrderedTrack.orderHash
        expect(appStateSlice.firstTrack) == firstOrderedTrack
        
        let nextOrderedTrack = orderedTracks[1]
        expect(appStateSlice.nextTrack) == nextOrderedTrack
    }
    
    func testSwitch() {
        
        prepareTrack()
        
        Dispatcher.dispatch(action: AudioPlayer.Play())
        expect(currentItem!.state.isPlaying).toEventually(equal(true))
        
        Dispatcher.dispatch(action: AudioPlayer.Switch())
        expect(currentItem!.state.isPlaying).toEventually(equal(false))
        
        Dispatcher.dispatch(action: AudioPlayer.Switch())
        expect(currentItem!.state.isPlaying).toEventually(equal(true))
    }
    
    func testPause() {
        prepareTrack()
        
        Dispatcher.dispatch(action: AudioPlayer.Play())
        expect(currentItem!.state.isPlaying).toEventually(equal(true))
        
        Dispatcher.dispatch(action: AudioPlayer.Pause())
        expect(currentItem!.state.isPlaying).toEventually(equal(false))
    }
    
    func testScrub() {
        
       prepareTrack()
        
        Dispatcher.dispatch(action: AudioPlayer.Scrub(newValue: 3))
        expect(currentItem!.state.progress).toEventually(equal(3))
        
        Dispatcher.dispatch(action: AudioPlayer.Scrub(newValue: 5))
        expect(currentItem!.state.progress).toEventually(equal(5))
    }
}

