//
//  ShuffleRepeat.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Shuffle: Action {
    
    enum ChangeType {
        case value(Bool)
        case toggle
    }; let change: ChangeType
    
    func perform(initialState: AppState) -> AppState {
        
        var x = initialState
        
        switch change {
        case .toggle:
            x.player.tracks.shouldShuffle.toggle()
            
        case .value(let value):
            x.player.tracks.shouldShuffle = value
        }
        
        return x
        
    }
    
}

struct Repeat: Action {

    enum ChangeType {
        case value(Bool)
        case toggle
    }; let change: ChangeType
    
    func perform(initialState: AppState) -> AppState {
        
        var x = initialState
        
        switch change {
        case .toggle:
            x.player.tracks.shouldRepeat.toggle()
            
        case .value(let value):
            x.player.tracks.shouldRepeat = value
            
        }
        
        return x
        
    }

}
