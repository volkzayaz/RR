//
//  PrepareLyricsTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class PrepareLyricsTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
    }
    
    func testPrepareLyrics() {
        
        let orderedTrack = orderedTracks[0]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [orderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: orderedTrack.track.artist.id)
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
        
        FakeRequest.Lyrics.registerMockRequestLyrics(track: t1)
        Dispatcher.dispatch(action: PrepareLyrics(for: t1))
        
        expect(currentItem?.lyrics).toNotEventually(beNil())
        expect(currentItem?.lyrics?.data.karaoke?.trackId) == t1.id
    }
}

