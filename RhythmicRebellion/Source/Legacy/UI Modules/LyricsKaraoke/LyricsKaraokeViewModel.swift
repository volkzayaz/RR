//
//  LyricsKaraokeContainerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxSwift
import RxCocoa
import Reachability
import RxReachability

final class LyricsKaraokeViewModel {

    private(set) weak var router: LyricsKaraokeRouter?

    let disposeBag = DisposeBag()

    init(router: LyricsKaraokeRouter) {
        self.router = router
    }

    func load() {

        ////React
        
        appState.map { $0.player.currentItem }
            .distinctUntilChanged()
            .drive(onNext: { [weak r = router] (currentItem) in
                
                guard case .karaoke(_)? = currentItem?.lyrics?.mode else {
                    r?.routeToLyrics()
                    return
                }
                
                r?.routeToKaraoke()
            })
            .disposed(by: disposeBag)
        
        ////Dispatch
        
        appState
            .distinctUntilChanged({ $0.currentTrack?.track == $1.currentTrack?.track &&
                                    $0.player.currentItem?.lyrics == $1.player.currentItem?.lyrics
            })
            .drive(onNext: { (state) in
                
                guard let t = state.currentTrack else { return }
                
                Dispatcher.dispatch(action: PrepareLyrics(for: t.track))
            })
            .disposed(by: disposeBag)
        
        
//        if let restApiServiceReachability = self.application.restApiServiceReachability {
//
//            restApiServiceReachability.rx.isReachable
//                .subscribe(onNext: { [unowned self] (isReachable) in
//                    guard isReachable, self.lyricsKaraokeService.lyricsState.value.isError else { return }
//                    self.lyricsKaraokeService.mode.accept(self.lyricsKaraokeService.mode.value)
//                })
//                .disposed(by: disposeBag)
//
//        }

    }
}
