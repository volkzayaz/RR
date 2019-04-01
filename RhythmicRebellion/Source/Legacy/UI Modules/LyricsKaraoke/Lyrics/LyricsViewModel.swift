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
            return state.player.currentItem?.lyrics?.data.karaoke != nil
            //                && self.player.currentItem.state.blocked == false
            //                && self.player.currentItem.state.waitingAddons == false
            //                && self.player.currentQueueItem?.isTrack == true
            
        }
    }
    
    var displayText: Driver<String> {
        
        return appState.map { state in
            
            if let t = state.player.currentItem?.lyrics?.data.lyrics {
                return t
            }
            
            guard let track = state.currentTrack?.track else {
                return ""
            }
            
            if track.isInstrumental {
                return "\n This is an instrumental song \n"
            }
            
            if track.isCensorship,
               let user = DataLayer.get.application.user,
               user.stubTrackAudioFileReason(for: track) == .censorship {
                return "\n Contains explicit material \n"
            }
            
            if track.previewType == .noPreview {
                return "\n No preview \n"
            }
            
            return ""
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
        guard DataLayer.get.application.user as? User != nil else {
            router?.routeToAuthorization(with: .signIn)
            return
        }

        Dispatcher.dispatch(action: ChangeLyricsMode(to: .karaoke(config: .init(track: .vocal, mode: .onePhrase))) )
    }
}
