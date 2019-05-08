//
//  ApplyReduxViewPatch.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import RxSwift

struct ApplyReduxViewPatch: ActionCreator {
    
    let viewPatch: PlayerState.ReduxViewPatch
    let assosiatedTracks: [Track]
    init (viewPatch: PlayerState.ReduxViewPatch, assosiatedTracks: [Track] = []) {
        self.viewPatch = viewPatch
        self.assosiatedTracks = assosiatedTracks
    }
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        ///getting state
        var state = initialState
        var tracks = state.player.tracks
        
        ///applying transform
        tracks.apply(patch: viewPatch)
        let allTrackIds = Set(tracks.reduxView.map { $0.value[.id]! as! Int })
        
        ///fetching underlying tracks if needed
        var tracksDiff = allTrackIds.subtracting(tracks.trackDump.keys)
        
        ///avoiding roundtrip to server
        assosiatedTracks.forEach { x in
            guard !tracksDiff.contains(x.id) else { return }
            tracks.trackDump[x.id] = x
            tracksDiff.remove(x.id)
        }
        
        ////setting state
        state.player.tracks = tracks
        state.player.lastPatch = viewPatch
        if viewPatch.shouldFlush {
            state.player.currentItem = nil
        }
        
        guard tracksDiff.count > 0 else {
            return .just(state)
        }
        
        return DataLayer.get.webSocketService
            .fetchTracks(trackIds: Array(tracksDiff))
            .map { receivedTracks -> AppState in

                receivedTracks.forEach { tracks.trackDump[$0.id] = $0 }
                state.player.tracks = tracks
                
                return state
        }
        
    }
    
}
