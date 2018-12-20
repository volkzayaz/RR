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

    private var application: Application
    private var player: Player

    private var lyrics: Lyrics? { return self.player.currentItem?.lyrics }

    var lyricsText: String? { return self.lyrics?.lyrics }
    private(set) var infoText: String = ""

    var canSwitchToKaraokeMode: Bool { return self.lyrics?.karaoke != nil }

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)
        self.application.removeWatcher(self)
    }

    init(router: LyricsRouter, application: Application ,player: Player) {
        self.router = router
        self.application = application
        self.player = player
    }

    func load(with delegate: LyricsViewModelDelegate) {
        self.delegate = delegate

        if let playerItem = self.player.currentItem {
            self.updateInfoText(for: playerItem.playlistItem.track)
        }

        self.delegate?.refreshUI()
        self.application.addWatcher(self)
        self.player.addWatcher(self)
    }

    func updateInfoText(for track: Track) {

        self.infoText = ""

        if  self.application.user?.isCensorshipTrack(track) ?? track.isCensorship {
            self.infoText.append("\n" + NSLocalizedString("Contains explisit material", comment: "Contains explisit material hint text") + "\n")
        }

        if track.isInstrumental {
            self.infoText.append("\n" + NSLocalizedString("This is an instrumental song", comment: "This is an instrumental song") + "\n")
        }
    }

    func switchToKaraoke() {
        guard self.application.user as? FanUser != nil else { self.router?.routeToAuthorization(with: .signIn); return }

        self.player.switchTo(karaokeMode: .karaoke)
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

        guard let playerItem = playerItem else {
            self.infoText = ""
            self.delegate?.refreshUI()
            return
        }

        self.updateInfoText(for: playerItem.playlistItem.track)
        self.delegate?.refreshUI()
    }
}

extension LyricsControllerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {

        guard let playerItem = self.player.currentItem, playerItem.playlistItem.track.id == trackForceToPlayState.trackId else { return }

        self.updateInfoText(for: playerItem.playlistItem.track)
        self.delegate?.refreshUI()

    }
}
