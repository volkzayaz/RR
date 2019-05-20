//
//  PlayAddonsTests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import XCTest
import Nimble
import RxCocoa

@testable import RhythmicRebellion

class PlayAddonsTests: XCTestCase {
    
    override func setUp() {
        
        initActorStorage(ActorStorage(actors: [], ws: FakeWebSocketService(), network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = [t1]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        FakeRequest.Artist.registerMockRequestArtist(artistId: firstOrderedTrack.track.artist.id)
    }
    
    func prepareNewTrack(_ register: ([Int]) -> Void) {
    
        let orderedTrack = orderedTracks[0]
        register([orderedTrack.track.id])
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(currentItem).toNotEventually(beNil())
        
        Dispatcher.dispatch(action: AudioPlayer.Play())
        expect(currentItem!.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
    
    func testPlayAdvertisementAddon() {
        prepareNewTrack { IDs in
            FakeRequest.Addons.registerAdvertisementAddon(withTrackIDs: IDs)
        }
        expect(appStateSlice.canForward) == false
    }
    
    func testPlaySongIntroductionAddon() {
        prepareNewTrack { IDs in
            FakeRequest.Addons.registerSongIntroductionAddon(withTrackIDs: IDs)
        }
        expect(appStateSlice.canForward) == false
    }
    
    func testPlaySongCommentaryAddon() {
        prepareNewTrack { IDs in
            FakeRequest.Addons.registerSongCommentaryAddon(withTrackIDs: IDs)
        }
        expect(appStateSlice.canForward) == true
    }
    
    func testPlayArtistBIOAddon() {
        prepareNewTrack { IDs in
            FakeRequest.Addons.registerArtistBIOAddon(withTrackIDs: IDs)
        }
        expect(appStateSlice.canForward) == true
    }
    
    func testPlayArtistAnnouncementsAddon() {
        prepareNewTrack { IDs in
            FakeRequest.Addons.registerArtistAnnouncementsAddon(withTrackIDs: IDs)
        }
        expect(appStateSlice.canForward) == false
    }
}

