//
//  PlayerState.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 2/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

fileprivate let _appState = BehaviorRelay<AppState?>(value: nil)

func initAppState() {
    
    let u = UserRequest.login.rx.baseResponse(type: User.self).asObservable()
    let c = ConfigRequest.player.rx.baseResponse(type: PlayerConfig.self).asObservable()
    
    let _ =
    Observable.combineLatest(u, c)
        .retryOnConnect(timeout: 1)
        .take(1)
        .map { (arg) in
            
            let (user, config) = arg
            
            return AppState(player: PlayerState(tracks: LinkedPlaylist(),
                                                lastPatch: nil,
                                                currentItem: nil,
                                                isBlocked: false,
                                                lastChangeSignatureHash: WebSocketService.ownSignatureHash,
                                                config: config),
                            user: user
            )
            
        }
        .bind(to: _appState)
}

var appStateSlice: AppState {
    return _appState.value!
}

var appState: Driver<AppState> {
    return _appState.asDriver().notNil()
}

//TODO: implement nice human readable string description of AppState

struct AppState: Equatable {
    
    var player: PlayerState
    var user: User
}

struct PlayerState: Equatable {
    
    var tracks: LinkedPlaylist
    var lastPatch: ReduxViewPatch?
    
    var currentItem: CurrentItem?
    var isBlocked: Bool
    
    ///represents whether last action was initiated by current client or some other client
    ///use `isOwn` to distinguish between two
    ///for example AudioPlayer might want to start playback only if currentClient initiated play
    ///but play button want to change it's state regardless of action origin
    var lastChangeSignatureHash: Signature
    
    struct CurrentItem: Equatable {
        let activeTrackHash: TrackOrderHash
        var addons: [Addon] //stack
        var state: TrackState
        var lyrics: Lyrics?
    }
    
    let config: PlayerConfig
    
    struct Lyrics: Equatable {
        let data: RhythmicRebellion.Lyrics
        var mode: Mode
        
        enum Mode: Equatable {
            case plain
            case karaoke(config: KaraokeConfig)
            
            struct KaraokeConfig: Equatable {
                
                var track: Track
                var mode: Mode
                
                enum Track { case backing, vocal }
                enum Mode { case scroll, onePhrase }
                
            }
            
        }
    }
    
    struct ReduxViewPatch {
        let shouldFlush: Bool
        var patch: LinkedPlaylist.NullableReduxView
    };
    
}

////shorthands
extension AppState {
    
    var currentTrack: OrderedTrack? {
        guard let hash = player.currentItem?.activeTrackHash,
              let t = player.tracks[hash] else {
                return nil
        }
        
        return t
    }
    
    var nextTrack: OrderedTrack? {
        guard let c = currentTrack else { return nil }
        return player.tracks.next(after: c.orderHash)
    }
    
    var firstTrack: OrderedTrack? {
        return player.tracks.orderedTracks.first
    }
 
    var canForward: Bool {
        
        guard case .addon(let addon)? = activePlayable else {
            return true
        }
        
        return addon.type == .artistBIO || addon.type == .songCommentary
        
    }

    var canBackward: Bool {
        return canForward
    }

    var canSeek: Bool {
        
        guard let x = activePlayable else { return false }
        
        switch x {
        case .track(_), .minusOneTrack(_): return true
        case .addon(_), .stub(_, _): return false
        }
        
    }
    
    enum MusicType: Equatable {
        case addon(Addon) /// small sounds prior to track such as announcements/intro/bio etc.
        case track(Track) /// audio track
        case minusOneTrack(Track) /// audio track without vocal for Karaoke
        case stub(DefaultAudioFile, explanation: String) /// audio stub in case track playback is not possible (no preview/censorship etc.)
    };
    
    var activePlayable: MusicType? {
        
        ///could be no track at all
        guard let currentItem = player.currentItem,
              let t = currentTrack?.track else {
            return nil
        }
        
        ///possible stubs
        if case .noPreview? = t.previewType, !user.isFollower(for: t.artist.id) {
            return .stub(player.config.noPreviewAudioFile,
                         explanation: t.name /*R.string.localizable.noPreviewMessage(t.artist.name)*/)
        }
        else if user.shouldCensorTrack(t) {
            return .stub(player.config.explicitMaterialAudioFile,
                         explanation: t.name /*R.string.localizable.recordingContainsExplicitMaterials(t.name)*/)
        }
        
        ///addon might be in the stack
        if let a = currentItem.addons.first {
            return .addon(a)
        }
        
        ///karaoke mode might ask us to play minusOne track
        if case .karaoke(let config)? = currentItem.lyrics?.mode,
           case .backing = config.track {
            return .minusOneTrack(t)
        }
        
        ///phew, regular track it is
        return .track(t)
    }
    
}

extension PlayerState.Lyrics.Mode.KaraokeConfig {
    var flipTrack: PlayerState.Lyrics.Mode.KaraokeConfig {
        var x = self
        
        switch x.track {
        case .backing: x.track = .vocal
        case .vocal:   x.track = .backing
        }
        
        return x
    }
}

extension Dispatcher {
    
    static var state: BehaviorRelay<AppState?> {
        return _appState
    }
    
}
