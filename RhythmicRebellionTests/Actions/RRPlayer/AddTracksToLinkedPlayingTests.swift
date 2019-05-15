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
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
    }
    
    func prepareForAddTracksToLinkedPlayin(trackToAdd track: Track, style: AddTracksToLinkedPlaying.AddStyle) {
        
        let firstOrderedTrack = orderedTracks[0]
        //Mocks Requests
        let addonUrl = try! TrackRequest.addons(trackIds: [firstOrderedTrack.track.id]).asURLRequest().url!
        FakeRequests.Addons.registerAdvertisementAddon(with: addonUrl)
        
        let artistUrl = try! TrackRequest.artist(artistId: firstOrderedTrack.track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrl)
        
        //Prepare new track
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: firstOrderedTrack, shouldPlayImmidiatelly: true))
        expect(player.currentItem).toNotEventually(beNil())
        
        let addonUrlToActive = try! TrackRequest.addons(trackIds: [track.id]).asURLRequest().url!
        FakeRequests.Addons.registerAdvertisementAddon(with: addonUrlToActive)
        
        let artistUrlToActive = try! TrackRequest.artist(artistId: track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrlToActive)
        
        Dispatcher.dispatch(action: AddTracksToLinkedPlaying(tracks: [track], style: style))
        expect(player.currentItem).toNotEventually(beNil())
    }
    
    func testAddTracksToLinkedPlayingNow() {
        
        prepareForAddTracksToLinkedPlayin(trackToAdd: t5, style: .next)
        expect(player.currentItem?.activeTrackHash) == orderedTracks[0].orderHash
        expect(orderedTracks[1].track.id) == t5.id
    }
    
    func testAddTracksToLinkedPlayingNext() {
        
        prepareForAddTracksToLinkedPlayin(trackToAdd: t2, style: .next)
        expect(player.currentItem?.activeTrackHash) == orderedTracks[0].orderHash
        expect(orderedTracks[1].track.id) == t2.id
    }
    
    func testAddTracksToLinkedPlayingLast() {
        
        prepareForAddTracksToLinkedPlayin(trackToAdd: t3, style: .last)
        expect(player.currentItem?.activeTrackHash) == orderedTracks[0].orderHash
        expect(orderedTracks[orderedTracks.count - 1].track.id) == t3.id
    }
}

