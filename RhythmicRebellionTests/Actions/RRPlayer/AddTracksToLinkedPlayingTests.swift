//
//  AddTracksToLinkedPlayingTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class AddTracksToLinkedPlayingTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
    }
    
    func testAddTracksToLinkedPlayingNow() {
        
        let tracks = Tracks.all
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
        
        let trackToPlayingNow = t5
        let addonUrlToActive = try! TrackRequest.addons(trackIds: [trackToPlayingNow.id]).asURLRequest().url!
        FakeRequests.Addons.registerAdvertisementAddon(with: addonUrlToActive)

        let artistUrlToActive = try! TrackRequest.artist(artistId: trackToPlayingNow.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrlToActive)
        
        expect(player.currentItem).toNotEventually(beNil())
        
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [trackToPlayingNow], style: .now))
        expect(player.currentItem).toNotEventually(beNil())
        
        let activeOrderedTrack = orderedTracks[0]
        expect(player.currentItem?.activeTrackHash) == activeOrderedTrack.orderHash
        expect(activeOrderedTrack.track.id) == trackToPlayingNow.id
        
    }
    
    func testAddTracksToLinkedPlayingNext() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: .next))
    }
    
    func testAddTracksToLinkedPlayingLast() {
        
        let tracks = [t1, t2, t3]
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: tracks, style: .last))
    }
}

