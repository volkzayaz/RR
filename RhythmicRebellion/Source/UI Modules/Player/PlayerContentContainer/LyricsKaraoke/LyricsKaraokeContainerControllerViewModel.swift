//
//  LyricsKaraokeContainerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class LyricsKaraokeContainerControllerViewModel: LyricsKaraokeContainerViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsKaraokeContainerViewModelDelegate?
    private(set) weak var router: LyricsKaraokeContainerRouter?

    private(set) var player: Player

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)

        if self.player.karaokeMode == .lyrics {
            self.player.switchTo(karaokeMode: .none)
        }
    }

    init(router: LyricsKaraokeContainerRouter, player: Player) {
        self.router = router
        self.player = player
    }

    func load(with delegate: LyricsKaraokeContainerViewModelDelegate) {
        self.delegate = delegate

        self.player.addWatcher(self)

        switch self.player.karaokeMode {
        case .none: self.player.switchTo(karaokeMode: .lyrics)
        case .lyrics: self.router?.routeToLyrics()
        case .karaoke:
            guard self.player.currentItem?.lyrics?.karaoke != nil else { self.router?.routeToLyrics(); return }
            self.router?.routeToKaraoke()
        }
    }
}

extension LyricsKaraokeContainerControllerViewModel: PlayerWatcher {

    func player(player: Player, didChangeKaraokeMode karaokeMode: Player.KaraokeMode) {

        switch karaokeMode {
        case .none: break
        case .lyrics: self.router?.routeToLyrics()
        case .karaoke: self.router?.routeToKaraoke()
        }
    }

    func player(player: Player, didLoadPlayerItemLyrics lyrics: Lyrics) {
        guard lyrics.karaoke != nil else { self.router?.routeToLyrics(); return }

        switch player.karaokeMode {
        case .none, .lyrics: self.router?.routeToLyrics()
        case .karaoke: self.router?.routeToKaraoke()
        }
    }

}
