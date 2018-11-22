//
//  PromoControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PromoControllerViewModel: PromoViewModel {

    var artistName: String? { return self.playerItem?.playlistItem.track.artist.name }
    var trackName: String? { return self.playerItem?.playlistItem.track.name }

    var infoText: String? { return self.playerItem?.playlistItem.track.radioInfo }

    var writerName: String? { return self.playerItem?.playlistItem.track.writer.name }

    var isAddonsSkipped: Bool {
        guard let artist = self.playerItem?.playlistItem.track.artist else { return false }
        return self.application.user?.isAddonsSkipped(for: artist) ?? false
    }

    var canVisitArtistSite: Bool { return self.playerItem?.playlistItem.track.artist.url != nil }
    var canVisitWriterSite: Bool { return self.playerItem?.playlistItem.track.writer.url != nil }

    var canToggleSkipAddons: Bool { return self.application.user?.isGuest == false && self.playerItem != nil }

    // MARK: - Private properties -

    private(set) weak var delegate: PromoViewModelDelegate?
    private(set) weak var router: PromoRouter?

    private(set) var application: Application
    private(set) var player: Player

    private var playerItem: PlayerItem? { return self.player.currentItem }


    // MARK: - Lifecycle -

    deinit {
        self.player.removeObserver(self)
        self.application.removeObserver(self)
    }

    init(router: PromoRouter, application: Application, player: Player) {
        self.router = router
        self.application = application
        self.player = player
    }

    func load(with delegate: PromoViewModelDelegate) {
        self.delegate = delegate

        self.delegate?.refreshUI()

        self.application.addObserver(self)
        self.player.addObserver(self)
    }

    func thumbnailURL() -> URL? {
        guard let trackImages = self.playerItem?.playlistItem.track.images else { return nil }

        let orderedImageLinksTypes: [ImageLinkType] = [.thumb, .small, .medium, .xsmall, .original, .big, .large, .xlarge, .preload]

        for trackImage in trackImages {
            guard let imageLink = trackImage.firstImageLink(from: orderedImageLinksTypes) else { continue }

            switch imageLink.path {
            case .url(let urlString):
                guard let imageLinkURL = URL(string: urlString) else { continue }
                return imageLinkURL
            default: continue
            }
        }

        return nil
    }

    func setSkipAddons(skip: Bool) {
        guard let artist = self.playerItem?.playlistItem.track.artist else { self.delegate?.refreshUI(); return }

        self.application.updateSkipAddons(for: artist, skip: skip) { [weak self] (error) in
            guard let error = error else { return }

            self?.delegate?.show(error: error)
        }
    }

    func navigateToPage(with url: URL) {
        self.router?.navigateToPage(with: url)
    }

    func visitArtistSite() {
        guard let artistURL = self.playerItem?.playlistItem.track.artist.url else { return }

        self.navigateToPage(with: artistURL)
    }

    func visitWriterSite() {
        guard let writerURL = self.playerItem?.playlistItem.track.writer.url else { return }

        self.navigateToPage(with: writerURL)
    }

    func navigateToAuthorization() {
        self.router?.navigateToAuthorization()
    }
}

extension PromoControllerViewModel: PlayerObserver {

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.delegate?.refreshUI()
    }
}

extension PromoControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState) {
        guard skipArtistAddonsState.artistId == self.playerItem?.playlistItem.track.artist.id else { return }

        self.delegate?.refreshUI()
    }
}
