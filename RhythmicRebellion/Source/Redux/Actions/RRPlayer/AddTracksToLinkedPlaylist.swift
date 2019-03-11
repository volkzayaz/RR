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
    
    let tracks: [Track]
    let style: RRPlayer.AddStyle
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        switch style {
        case .next:
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
            
        case .now:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.currentTrack, isOwnChange: true)
                .perform(initialState: initialState)
                .flatMap { newState -> Observable<AppState> in
                    
                    guard let newCurrentTrack = newState.nextTrack ?? newState.firstTrack else {
                        return .just(newState)
                    }
                    
                    return PrepareNewTrack(orderedTrack: newCurrentTrack,
                                           shouldPlayImmidiatelly: true).perform(initialState: newState)
            }
            
        case .last:
            
            return InsertTracks(tracks: tracks, afterTrack: initialState.player.tracks.orderedTracks.last, isOwnChange: true)
                .perform(initialState: initialState)
            
        }
        
        
    }
    
}
