//
//  FakeAppState.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//


@testable import RhythmicRebellion

class TestRRPlayer: RRPlayer {
    override init() {
        super.init()
    }
}

extension RouterDependencies: Fakeble {
    static func fake() -> RouterDependencies {
        return RouterDependencies(daPlayer: TestRRPlayer())
    }
}

extension AppState: Fakeble {

    static func fake() -> AppState {
        return AppState(player: PlayerState.fake(), user: User.fake())
    }
}


extension LinkedPlaylist: Fakeble {
    static func fake() -> LinkedPlaylist {
        return LinkedPlaylist()
    }
}

extension PlayerState: Fakeble {
    static func fake() -> PlayerState {
        
        let playerState = PlayerState(tracks: LinkedPlaylist.fake(),
                                      lastPatch: nil,
                                      currentItem: nil,
                                      isBlocked: false,
                                      lastChangeSignatureHash: WebSocketService.ownSignatureHash,
                                      config: PlayerConfig.fake())
        
        return playerState
    }
}
