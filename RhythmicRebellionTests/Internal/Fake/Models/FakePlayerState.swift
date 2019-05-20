//
//  FakePlayerState.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension PlayerState: Fakeble {
    
    static func fake() -> PlayerState {
        
        let playerState = PlayerState(tracks: LinkedPlaylist.fake(),
                                      lastPatch: nil,
                                      currentItem: nil,
                                      isBlocked: false,
                                      myPlaylists: [],
                                      lastChangeSignatureHash: WebSocketService.ownSignatureHash,
                                      config: PlayerConfig.fake())
        
        return playerState
    }
}
