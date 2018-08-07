//
//  PlayerMyPlaylistsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerMyPlaylistsControllerViewModel: PlayerMyPlaylistsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerMyPlaylistsViewModelDelegate?
    private(set) weak var router: PlayerMyPlaylistsRouter?

    // MARK: - Lifecycle -

    init(router: PlayerMyPlaylistsRouter) {
        self.router = router
    }

    func load(with delegate: PlayerMyPlaylistsViewModelDelegate) {
        self.delegate = delegate
    }
}
