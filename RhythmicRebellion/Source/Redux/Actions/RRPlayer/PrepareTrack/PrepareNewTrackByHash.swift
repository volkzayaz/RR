//
//  PrepareNewTrackByHash.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

////Used exclusivelly for changing track in response to WebScoket.
////iOS modules leverage |PrepareNewTrack| action
struct PrepareNewTrackByHash: ActionCreator {
    
    let orderHash: TrackOrderHash?
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        guard let orderHash = orderHash else {
            var s = initialState
            s.player.currentItem = nil
            return .just(s)
        }
        
        guard let x = initialState.player.tracks[orderHash] else {
            fatalErrorInDebug(" Can't start playing track with order key: \(orderHash). It is not found in reduxView: \(initialState.player.tracks) ")
            return .just(initialState)
        }
        
        return PrepareNewTrack(orderedTrack: x,
                               shouldPlayImmidiatelly: false,
                               canSkipAddons: true).perform(initialState: initialState)
    }
    
}
