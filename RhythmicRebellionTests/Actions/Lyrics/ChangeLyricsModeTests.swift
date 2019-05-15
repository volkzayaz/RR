//
//  ChangeLyricsModeTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class ChangeLyricsModeTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = Tracks.all
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let orderedTrack = orderedTracks[0]
        FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: [orderedTrack.track.id])
        FakeRequest.Artist.registerMockRequestArtist(artistId: orderedTrack.track.artist.id)
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(currentItem?.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
        
        FakeRequest.Lyrics.registerMockRequestLyrics(track: t1)
        Dispatcher.dispatch(action: PrepareLyrics(for: t1))
        expect(currentItem?.lyrics).toNotEventually(beNil())
        expect(currentItem?.lyrics?.data.karaoke).toNot(beNil())
        expect(currentItem?.lyrics?.data.lyrics).toNot(beNil())
        
        let newState = TrackState(progress: 5, isPlaying: false, skipSeek: ())
        Dispatcher.dispatch(action: ChangeTrackState(trackState: newState))
        
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToPlain() {
        
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .plain))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.plain))
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToKaraokeVocalOnePhrase() {
        
        let config = PlayerState.Lyrics.Mode.KaraokeConfig(track: .vocal, mode: .onePhrase)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: config)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: config)))
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToKaraokeVocalScroll() {
        let config = PlayerState.Lyrics.Mode.KaraokeConfig(track: .vocal, mode: .scroll)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: config)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: config)))
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToKaraokeBackingPhrase() {
        let config = PlayerState.Lyrics.Mode.KaraokeConfig(track: .backing, mode: .onePhrase)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: config)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: config)))
        expect(currentTrack?.track.backingAudioFile).toNot(beNil())
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToKaraokeBackingScroll() {
        let config = PlayerState.Lyrics.Mode.KaraokeConfig(track: .backing, mode: .scroll)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: config)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: config)))
        expect(currentItem?.state.progress) == 5
    }
    
    func testChangeLyricsModeToKaraokeResetProgress() {
        let config = PlayerState.Lyrics.Mode.KaraokeConfig(track: .backing, mode: .scroll)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: config)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: config)))
        expect(currentItem?.state.progress) == 5
        
        let vocalConfig = PlayerState.Lyrics.Mode.KaraokeConfig(track: .vocal, mode: .scroll)
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: vocalConfig)))
        expect(currentItem?.lyrics?.mode).toEventually(equal(.karaoke(config: vocalConfig)))
        expect(currentItem?.state.progress) == 0
    }
}
