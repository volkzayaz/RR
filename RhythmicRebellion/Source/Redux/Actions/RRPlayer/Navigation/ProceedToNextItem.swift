//
//  ProceedToNextItem.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 3/11/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

////TODO: Proceed To Next Item and Prepare new track share a lot of logic
////especially in preparing addon.
////We need to extract this logic into unified concept
////without scattering Addons through multiple ActionCreators
struct ProceedToNextItem: ActionCreator {
    
    func perform(initialState: AppState) -> Observable<AppState> {
        
        guard var currentItem = initialState.player.currentItem,
            let currentTrack = initialState.currentTrack else {
                return .just(initialState)
        }
        
        var state = initialState
        
        if currentItem.addons.count > 0 {
            var addons = currentItem.addons
            let next = addons.removeFirst()
            
            currentItem.addons = addons
            
            state.player.currentItem = currentItem
            
            DataLayer.get.webSocketService.markPlayed(addon: next,
                                                      for: currentTrack.track)
            
            return .just(state)
        }
        else if let next = state.nextTrack {
            return PrepareNewTrack(orderedTrack: next,
                                   shouldPlayImmidiatelly: true).perform(initialState: state)
        }
        
        return .just(state)
    }
    
}
