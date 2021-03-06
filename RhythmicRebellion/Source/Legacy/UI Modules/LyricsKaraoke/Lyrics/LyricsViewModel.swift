//
//  LyricsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxSwift
import RxCocoa

extension LyricsViewModel {
    
    var canSwitchToKaraoke: Driver<Bool> {
        return appState.map { state in
            
            if let track = state.currentTrack?.track,
               case .noPreview = TrackPreviewOptionViewModel(type: .init(with: track, user: state.user)).type {
                return false
            }
            
            return state.player.currentItem?.lyrics?.data.karaoke != nil
            //                && self.player.currentItem.state.blocked == false
            //                && self.player.currentItem.state.waitingAddons == false
            //                && self.player.currentQueueItem?.isTrack == true
            
        }
    }
    
    var displayText: Driver<String> {
        
        return appState.map { state in
            
            guard let track = state.currentTrack?.track else {
                return ""
            }
            
            if track.isInstrumental {
                return "\n This is an instrumental song \n"
            }
            
            if case .noPreview = TrackPreviewOptionViewModel(type: .init(with: track, user: state.user)).type {
                return "\n No preview \n"
            }
            
            if state.user.shouldCensorTrack(track) {
                return "\n Contains explicit material \n"
            }
            
            if let t = state.player.currentItem?.lyrics?.data.lyrics {
                return t
            }
            
            return "No Lyrics available"
        }
        
    }
    
}

final class LyricsViewModel {

    // MARK: - Private properties -

    private(set) weak var router: LyricsRouter?
    
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -
    init(router: LyricsRouter) {
        self.router = router
    }

    func switchToKaraoke() {
        guard !appStateSlice.user.isGuest else {
            //router?.routeToAuthorization(with: .signIn)
            return
        }

        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: .init(track: .vocal, mode: .onePhrase))) )
    }
}
