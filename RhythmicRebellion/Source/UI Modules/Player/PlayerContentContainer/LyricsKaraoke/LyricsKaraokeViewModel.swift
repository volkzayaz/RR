//
//  LyricsKaraokeContainerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class LyricsKaraokeViewModel: LyricsKaraokeViewModelProtocol {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsKaraokeViewModelDelegate?
    private(set) weak var router: LyricsKaraokeRouter?

    private(set) var application: Application
    private(set) var player: Player

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)

        if self.player.karaokeMode == .lyrics {
            self.player.switchTo(karaokeMode: .none)
        }
    }

    init(router: LyricsKaraokeRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player
    }

    func load(with delegate: LyricsKaraokeViewModelDelegate) {
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

extension LyricsKaraokeViewModel: PlayerWatcher {

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        guard let playerItemTrack = playerItem?.playlistItem.track else { self.router?.routeToLyrics(); return }

        var isCensorshipTrack = playerItemTrack.isCensorship
        if isCensorshipTrack == true, let user = self.application.user {
            isCensorshipTrack = user.stubTrackAudioFileReason(for: playerItemTrack) == .censorship
        }

        if isCensorshipTrack == true ||
            playerItemTrack.isInstrumental == true ||
            playerItemTrack.previewType == .noPreview {
            self.router?.routeToLyrics()
        }
    }

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
