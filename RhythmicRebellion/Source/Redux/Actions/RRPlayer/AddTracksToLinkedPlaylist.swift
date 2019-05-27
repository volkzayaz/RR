//
//  AddTracksToLinkedPlaylist.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct AddTracksToLinkedPlaying: ActionCreator {
    
    enum AddStyle {
        case now, next, last
    }
    
    let tracks: [Track]
    let style: AddStyle
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        let playableTracks = tracks.filter { $0.isPlayable }
        
        switch style {
        case .next:
            return InsertTracks(tracks: playableTracks, afterTrack: initialState.currentTrack)
                .perform(initialState: initialState)
            
        case .now:
            
            return InsertTracks(tracks: playableTracks, afterTrack: initialState.currentTrack)
                .perform(initialState: initialState)
                .flatMap { newState -> Observable<AppState> in
                    
                    guard let newCurrentTrack = newState.nextTrack ?? newState.firstTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: newCurrentTrack,
                                           shouldPlayImmidiatelly: true).perform(initialState: newState)
            }
            
        case .last:
            
            return InsertTracks(tracks: playableTracks, afterTrack: initialState.player.tracks.orderedTracks.last)
                .perform(initialState: initialState)
            
        }
        
    }
    
}
