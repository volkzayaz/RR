//
//  PlayerState.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxCocoa

private let _appState: BehaviorRelay<AppState> = {
    
    let x = AppState(player: DaPlayerState(playlist: DaPlayerState.Playlist(tracks: DaPlaylist(),
                                                                            addons: [],
                                                                            activeTrackHash: nil),
                                           playingNow: DaPlayerState.PlayingNow(musicType: nil,
                                                                                isPlaying: false,
                                                                                currentProgress: 0),
                                           isBlocked: false),
                     trackDump: [] )
    
    return BehaviorRelay(value: x)
    
}()

var appState: Driver<AppState> {
    return _appState.asDriver()
}

struct AppState {
    
    var player: DaPlayerState
    
//    let user: User
    var trackDump: Set<Track>
    
}

struct DaPlayerState {
    
    struct Playlist {
        
        var tracks: DaPlaylist
        var addons: [Addon] //stack
        var activeTrackHash: TrackOrderHash?
        
    }; var playlist: Playlist
    
    struct PlayingNow {
        
        enum MusicType {
            case addon(Addon)
            case track(Track)
        }; var musicType: MusicType?
        
        var isPlaying: Bool
        var currentProgress: TimeInterval
        
    }; var playingNow: PlayingNow
    
    var isBlocked: Bool
    
}


enum Dispatcher {
    
    static func dispatch(action: Action) {
        
        let newState = action.perform(initialState: _appState.value)
        _appState.accept(newState)
        
    }
    
}

protocol Action {
    
    func perform( initialState: AppState ) -> AppState
    
}
