//
//  KaraokeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class KaraokeControllerViewModel: KaraokeViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: KaraokeViewModelDelegate?
    private(set) weak var router: KaraokeRouter?

    private(set) var player: Player

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)
    }

    init(router: KaraokeRouter, player: Player) {
        self.router = router
        self.player = player
    }

    func load(with delegate: KaraokeViewModelDelegate) {
        self.delegate = delegate

        self.delegate?.refreshUI()

        self.player.addWatcher(self)
    }

    func switchToLyrics() {
        self.player.switchTo(karaokeMode: .lyrics)
    }
}

extension KaraokeControllerViewModel: PlayerWatcher {

}
