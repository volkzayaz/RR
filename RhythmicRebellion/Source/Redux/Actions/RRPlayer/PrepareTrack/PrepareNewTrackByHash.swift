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
            
            ///----
            ///WebSocket team refuses to implement this rule on their side, so each client enforces the rule manually
            ///Receiving null as current track does not mean "nothing is currently playing"
            ///It means "the first track from the list if present is currently playing" ¯\_(ツ)_/¯
            ///Ideally we should keep our client as dumb as possible
            ///And this rule must be enforced on server side
            ///----
            if let first = initialState.player.tracks.orderedTracks.first {
                return PrepareNewTrack(orderedTrack: first,
                                       shouldPlayImmidiatelly: false,
                                       canSkipAddons: true).perform(initialState: initialState)
            }
            
            var s = initialState
            s.player.currentItem = nil
            return .just(s)
        }
        
        guard initialState.currentTrack?.orderHash != orderHash else {
            return .just(initialState)
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
