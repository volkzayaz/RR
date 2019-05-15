//
//  Helpers.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

var lastPatch: PlayerState.ReduxViewPatch? {
    return player.lastPatch
}

var player: PlayerState {
    return appStateSlice.player
}

var currentItem: PlayerState.CurrentItem? {
    return player.currentItem
}

var currentTrack: OrderedTrack? {
    return appStateSlice.currentTrack
}

var orderedTracks: [OrderedTrack] {
    return player.tracks.orderedTracks
}
