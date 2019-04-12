//
//  PrepareLyrics.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/27/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

struct PrepareLyrics: ActionCreator {
    
    let `for`: Track
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        let t = `for`
        
        guard t.isPlayable, !t.isInstrumental else {
            return .just(initialState)
        }
        
        if initialState.currentTrack?.track == t,
            initialState.player.currentItem?.lyrics != nil {
            return .just(initialState)
        }
        
        return TrackRequest.lyrics(track: t)
            .rx.response(type: BaseReponse<Lyrics>.self)
            .asObservable()
            .map { resp in
                var state = initialState
                state.player.currentItem?.lyrics = .init(data: resp.data,
                                                         mode: .plain)
                return state
            }
        
        
    }
    
}
