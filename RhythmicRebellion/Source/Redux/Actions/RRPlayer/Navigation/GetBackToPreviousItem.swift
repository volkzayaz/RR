//
//  GetBackToPreviousItem.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct GetBackToPreviousItem: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        if let s = initialState.player.currentItem, s.state.progress > 3 {
            
            var state = initialState
            state.player.currentItem?.state = .init(progress: 0, isPlaying: true)
            return .just(state)
            
        }
        
        guard let currentHash = initialState.currentTrack?.orderHash,
            let previousItem = initialState.player.tracks.previous(before: currentHash) else {
                return .just(initialState)
        }
        
        return PrepareNewTrack(orderedTrack: previousItem,
                               shouldPlayImmidiatelly: true).perform(initialState: initialState)
    }
    
}

