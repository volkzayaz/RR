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
        
        initActorStorage(ActorStorage(actors: [],
                                      ws: FakeWebSocketService(),
                                      network: FakeNetwork()))
        Dispatcher.state.accept(AppState.fake())
        
        let tracks = [t1]
        Dispatcher.dispatch(action: InsertTracks(tracks: tracks, afterTrack: nil))
        expect(player.tracks.count).toEventually(equal(tracks.count))
        
        let firstOrderedTrack = orderedTracks[0]
        //Mock Requests
        let artistUrl = try! TrackRequest.artist(artistId: firstOrderedTrack.track.artist.id).asURLRequest().url!
        FakeRequests.registerMockRequestArtist(with: artistUrl)
    }
    
    func prepareNewTrack(_ register: (URL) -> Void) {
        //Prepare new track
        let orderedTrack = orderedTracks[0]
        //Mock Requests
        let addonUrl = try! TrackRequest.addons(trackIds: [orderedTrack.track.id]).asURLRequest().url!
        register(addonUrl)
        
        Dispatcher.dispatch(action: PrepareNewTrack(orderedTrack: orderedTrack, shouldPlayImmidiatelly: false))
        expect(player.currentItem).toNotEventually(beNil())
        //Play Action
        Dispatcher.dispatch(action: AudioPlayer.Play())
        expect(player.currentItem!.activeTrackHash).toEventually(equal(orderedTrack.orderHash))
    }
    
    func testPlayAdvertisementAddon() {
        prepareNewTrack { addonUrl in
            FakeRequests.Addons.registerAdvertisementAddon(with: addonUrl)
        }
        expect(appStateSlice.canForward) == false
    }
    
    func testPlaySongIntroductionAddon() {
        prepareNewTrack { addonUrl in
            FakeRequests.Addons.registerSongIntroductionAddon(with:  addonUrl)
        }
        expect(appStateSlice.canForward) == false
    }
    
    func testPlaySongCommentaryAddon() {
        prepareNewTrack { addonUrl in
            FakeRequests.Addons.registerSongCommentaryAddon(with: addonUrl)
        }
        expect(appStateSlice.canForward) == true
    }
    
    func testPlayArtistBIOAddon() {
        prepareNewTrack { addonUrl in
            FakeRequests.Addons.registerArtistBIOAddon(with: addonUrl)
        }
        expect(appStateSlice.canForward) == true
    }
    
    func testPlayArtistAnnouncementsAddon() {
        prepareNewTrack { addonUrl in
            FakeRequests.Addons.registerArtistAnnouncementsAddon(with: addonUrl)
        }
        expect(appStateSlice.canForward) == false
    }
}

