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

final class LyricsViewModel: LyricsViewModelProtocol {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsViewModelDelegate?
    private(set) weak var router: LyricsRouter?

    private var application: Application
    private var lyricsKaraokeService: LyricsKaraokeService

    private var lyrics: Lyrics?
    var lyricsText: String? { return self.lyrics?.lyrics }
    private(set) var infoText: String = ""

    var canSwitchToKaraokeMode: Bool { return self.lyrics?.karaoke != nil
//                                        && self.player.currentItem.state.blocked == false
//                                        && self.player.currentItem.state.waitingAddons == false
//                                        && self.player.currentQueueItem?.isTrack == true
    }

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -
    init(router: LyricsRouter, application: Application, lyricsKaraokeService: LyricsKaraokeService) {
        self.router = router
        self.application = application
        self.lyricsKaraokeService = lyricsKaraokeService
    }

    func load(with delegate: LyricsViewModelDelegate) {
        self.delegate = delegate

        self.lyricsKaraokeService.lyricsState
            .subscribe(onNext: { (lyricsState) in

            self.infoText = ""
            self.lyrics = nil

            switch lyricsState {
            case .lyrics(let lyrics):
                self.lyrics = lyrics

            default: break
//                guard let playerItem = self.player.currentItem else { return }
//                self.updateInfoText(for: playerItem.playlistItem.track)
            }
            self.delegate?.refreshUI()
        })
        .disposed(by: disposeBag)


    }

    func updateInfoText(for track: Track) {

        self.infoText = ""

        if track.isInstrumental {
            self.infoText.append("\n" + NSLocalizedString("This is an instrumental song", comment: "This is an instrumental song") + "\n")
        }

        var isCensorshipTrack = track.isCensorship
        if isCensorshipTrack == true, let user = self.application.user {
            isCensorshipTrack = user.stubTrackAudioFileReason(for: track) == .censorship
        }

        if  isCensorshipTrack  {
            self.infoText.append("\n" + NSLocalizedString("Contains explicit material", comment: "Contains explicit material hint text") + "\n")
        }

        if track.previewType == .noPreview {
            self.infoText.append("\n" + NSLocalizedString("No preview", comment: "No preview text") + "\n")
        }
    }

    func switchToKaraoke() {
        guard self.application.user as? FanUser != nil else { self.router?.routeToAuthorization(with: .signIn); return }

        self.lyricsKaraokeService.mode.accept(.karaoke)
    }
}

extension LyricsViewModel {
    func player(didChangeBlockedState isBlocked: Bool) {
        self.delegate?.refreshUI()
    }

    func player(didChangePlayerQueueItem playerQueueItem: Void /*PlayerQueueItem*/) {
        self.delegate?.refreshUI()
    }
}
