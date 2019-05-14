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
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testPlayFirstTrack() {
        
        let tracks = [t1, t2, t2]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        //Mock Requests
        let addonUrl = try! TrackRequest.addons(trackIds: [firstOrderedTrack.track.id]).asURLRequest().url!
        FakeRequests.Addons.registerAdvertisementAddon(with: addonUrl)
        
        let artistUrl = try! TrackRequest.artist(artistId: firstOrderedTrack.track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrl)
        //Prepare new track
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: false))
        expect(player.currentItem).toNotEventually(beNil())
        //Play Action
        Dispatcher.dispatch(action: AudioPlayer.Play())
        
        expect(player.currentItem!.state.isPlaying).toEventually(equal(true))
        expect(player.currentItem!.activeTrackHash).toEventually(equal(firstOrderedTrack.orderHash))
        
        expect(appStateSlice.firstTrack) == firstOrderedTrack
        
        let nextOrderedTrack = orderedTracks[1]
        expect(appStateSlice.nextTrack) == nextOrderedTrack
    }
}

