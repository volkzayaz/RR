//
//  Helper.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

var lastPatch: PlayerState.ReduxViewPatch? {
    return appStateSlice.player.lastPatch
}

var player: PlayerState {
    return appStateSlice.player
}

var orderedTracks: [OrderedTrack] {
    return appStateSlice.player.tracks.orderedTracks
}
