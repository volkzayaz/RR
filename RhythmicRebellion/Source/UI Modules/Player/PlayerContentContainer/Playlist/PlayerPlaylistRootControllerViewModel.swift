//
//  PlayerPlaylistRootControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerPlaylistRootControllerViewModel: PlayerPlaylistRootViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerPlaylistRootViewModelDelegate?
    private(set) weak var router: PlayerPlaylistRootRouter?

    // MARK: - Lifecycle -

    init(router: PlayerPlaylistRootRouter) {
        self.router = router
    }

    func load(with delegate: PlayerPlaylistRootViewModelDelegate) {
        self.delegate = delegate
    }
}
