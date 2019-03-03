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

final class LyricsKaraokeViewModel: LyricsKaraokeViewModelProtocol {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsKaraokeViewModelDelegate?
    private(set) weak var router: LyricsKaraokeRouter?

    private(set) var application: Application
    private(set) var lyricsKaraokeService: LyricsKaraokeService

    private(set) var lyricsStateError: BehaviorRelay<Error?> = BehaviorRelay(value: nil)

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    deinit {
        if self.lyricsKaraokeService.mode.value == .lyrics {
            self.lyricsKaraokeService.mode.accept(.none)
        }
    }

    init(router: LyricsKaraokeRouter, application: Application, lyricsKaraokeService: LyricsKaraokeService) {
        self.router = router
        self.application = application
        self.lyricsKaraokeService = lyricsKaraokeService
    }

    func load(with delegate: LyricsKaraokeViewModelDelegate) {
        self.delegate = delegate

        self.lyricsKaraokeService.lyricsState
            .subscribe(onNext: { [weak self] (lyricsState) in

                guard let self = self else { return }

                self.lyricsStateError.accept(nil)

                switch lyricsState {
                case .unknown: break
                case .none:
                    self.router?.routeToLyrics()
                case .lyrics(let lyrics):
                    guard lyrics.karaoke != nil, self.lyricsKaraokeService.mode.value == .karaoke else {
                        self.router?.routeToLyrics()
                        return
                    }

                    self.router?.routeToKaraoke()

                case .error(let error):
                    self.router?.routeToLyrics()
                    self.lyricsStateError.accept(error)
                }
            })
            .disposed(by: disposeBag)


        self.lyricsKaraokeService.mode.subscribe(onNext: { [weak self] (mode) in

            guard let self = self else { return }

            switch mode {
            case .karaoke:
                switch self.lyricsKaraokeService.lyricsState.value {
                case .lyrics(let lyrics):
                    guard lyrics.karaoke != nil else {
                        self.router?.routeToLyrics()
                        return
                    }
                    self.router?.routeToKaraoke()

                default: self.router?.routeToLyrics()
                }

            default: self.router?.routeToLyrics()
            }
        })
        .disposed(by: disposeBag)

        if let restApiServiceReachability = self.application.restApiServiceReachability {

            restApiServiceReachability.rx.isReachable
                .subscribe(onNext: { [unowned self] (isReachable) in
                    guard isReachable, self.lyricsKaraokeService.lyricsState.value.isError else { return }
                    self.lyricsKaraokeService.mode.accept(self.lyricsKaraokeService.mode.value)
                })
                .disposed(by: disposeBag)
        }

        if self.lyricsKaraokeService.mode.value == .none {
            self.lyricsKaraokeService.mode.accept(.lyrics)
        }
    }
}
