//
//  RemoveTrack.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct RemoveTrack: ActionCreator {
    
    let orderedTrack: OrderedTrack
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        var maybeNextTrack: OrderedTrack? = nil
        if initialState.currentTrack == orderedTrack {
            maybeNextTrack = initialState.nextTrack ?? initialState.firstTrack
        }
        
        return DeleteTrack(track: orderedTrack, isOwnChange: true)
            .perform(initialState: initialState)
            .flatMap { newState -> Observable<AppState> in
                
                guard let c = maybeNextTrack else {
                    return .just(newState)
                }
                
                return PrepareNewTrack(orderedTrack: c,
                                       shouldPlayImmidiatelly: initialState.player.currentItem?.state.isPlaying ?? false)
                    .perform(initialState: newState)
                
        }
        
    }
    
}
