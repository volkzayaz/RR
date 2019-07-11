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
            
            if case .noPreview? = state.previewOptions?.audioRestriction {
                return false
            }
            
            if let t = state.currentTrack?.track, state.user.shouldCensorTrack(t) {
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
            
            if case .noPreview? = state.previewOptions?.audioRestriction {
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

struct LyricsViewModel {

    // MARK: - Private properties -

    private let router: LyricsRouter
    
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -
    init(router: LyricsRouter) {
        self.router = router
    }

    func switchToKaraoke() {
        
        guard !appStateSlice.user.isGuest else {
            
            ////TODO: kill it with fire!!
            router.owner?.dismissController()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToSignIn"), object: nil)
            
            return
        }
        
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: .init(track: .vocal, mode: .onePhrase))) )
    }
}
