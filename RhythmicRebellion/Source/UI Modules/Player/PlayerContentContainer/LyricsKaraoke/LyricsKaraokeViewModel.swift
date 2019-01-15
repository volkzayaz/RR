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

final class LyricsKaraokeViewModel: LyricsKaraokeViewModelProtocol {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsKaraokeViewModelDelegate?
    private(set) weak var router: LyricsKaraokeRouter?

    private(set) var application: Application
    private(set) var player: Player
    private(set) var lyricsKaraokeService: LyricsKaraokeService

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)

        if self.player.karaokeMode == .lyrics {
            self.player.switchTo(karaokeMode: .none)
        }

        if self.lyricsKaraokeService.mode.value == .lyrics {
            self.lyricsKaraokeService.mode.accept(.none)
        }
    }

    init(router: LyricsKaraokeRouter, application: Application, player: Player, lyricsKaraokeService: LyricsKaraokeService) {
        self.router = router
        self.application = application
        self.player = player
        self.lyricsKaraokeService = lyricsKaraokeService
    }

    func load(with delegate: LyricsKaraokeViewModelDelegate) {
        self.delegate = delegate

        self.player.addWatcher(self)

        self.lyricsKaraokeService.lyricsState
            .subscribe(onNext: { [weak self] (lyricsState) in

                guard let self = self else { return }

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
                    self.delegate?.show(error: error)
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

        if self.lyricsKaraokeService.mode.value == .none {
            self.lyricsKaraokeService.mode.accept(.lyrics)
        }

//        switch self.player.karaokeMode {
//        case .none:
//            self.player.switchTo(karaokeMode: .lyrics)
//            self.lyricsKaraokeService.mode.accept(.lyrics)
//
//        case .lyrics: self.router?.routeToLyrics()
//        case .karaoke:
//            guard self.player.currentItem?.lyrics?.karaoke != nil else { self.router?.routeToLyrics(); return }
//            self.router?.routeToKaraoke()
//        }
    }
}

extension LyricsKaraokeViewModel: PlayerWatcher {

//    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
//        guard let playerItemTrack = playerItem?.playlistItem.track else { self.router?.routeToLyrics(); return }
//
//        var isCensorshipTrack = playerItemTrack.isCensorship
//        if isCensorshipTrack == true, let user = self.application.user {
//            isCensorshipTrack = user.stubTrackAudioFileReason(for: playerItemTrack) == .censorship
//        }
//
//        if isCensorshipTrack == true ||
//            playerItemTrack.isInstrumental == true ||
//            playerItemTrack.previewType == .noPreview {
//            self.router?.routeToLyrics()
//        }
//    }
//
//    func player(player: Player, didChangeKaraokeMode karaokeMode: Player.KaraokeMode) {
//
//        switch karaokeMode {
//        case .none: break
//        case .lyrics: self.router?.routeToLyrics()
//        case .karaoke: self.router?.routeToKaraoke()
//        }
//    }
//
//    func player(player: Player, didLoadPlayerItemLyrics lyrics: Lyrics) {
//        guard lyrics.karaoke != nil else { self.router?.routeToLyrics(); return }
//
//        switch player.karaokeMode {
//        case .none, .lyrics: self.router?.routeToLyrics()
//        case .karaoke: self.router?.routeToKaraoke()
//        }
//    }

}
