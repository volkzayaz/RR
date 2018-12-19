//
//  LyricsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class LyricsControllerViewModel: LyricsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsViewModelDelegate?
    private(set) weak var router: LyricsRouter?

    private var player: Player

    private var lyrics: Lyrics? { return self.player.currentItem?.lyrics }

    var lyricsText: String? { return self.lyrics?.lyrics }
    var canSwitchToKaraokeMode: Bool { return self.lyrics?.karaoke != nil }

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)

        if self.player.karaokeMode == .lyrics {
            self.player.switchTo(karaokeMode: .none)
        }
    }

    init(router: LyricsRouter, player: Player) {
        self.router = router
        self.player = player
    }

    func load(with delegate: LyricsViewModelDelegate) {
        self.delegate = delegate

        self.delegate?.refreshUI()

        if self.player.karaokeMode == .none {
            self.player.switchTo(karaokeMode: .lyrics)
        }

        self.player.addWatcher(self)
    }

    func switchToKaraokeMode() {

    }
}

extension LyricsControllerViewModel: PlayerWatcher {

    func player(player: Player, didLoadPlayerItemLyrics lyrics: Lyrics) {
        self.delegate?.refreshUI()
    }

    func player(player: Player, didFailedLoadPlayerItemLyrics error: Error) {
        self.delegate?.show(error: error)
    }

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.delegate?.refreshUI()
    }
}
