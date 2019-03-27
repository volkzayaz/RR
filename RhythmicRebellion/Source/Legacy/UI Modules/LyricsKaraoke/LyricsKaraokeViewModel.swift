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
                    r?.routeToKaraoke()
                    return
                }
                
                r?.routeToLyrics()
            })
            .disposed(by: disposeBag)
        
        ////Dispatch
        
        ///TODO: take into account user changes in explicit materials and forceToPlay
        appState.map { $0.currentTrack?.track }
            .notNil()
            .distinctUntilChanged()
            .drive(onNext: { (track) in
                Dispatcher.dispatch(action: PrepareLyrics(for: track))
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
