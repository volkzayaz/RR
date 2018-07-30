//
//  PlaylistControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlaylistControllerViewModel: PlaylistViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistViewModelDelegate?
    private(set) weak var router: PlaylistRouter?

    // MARK: - Lifecycle -

    init(router: PlaylistRouter) {
        self.router = router
    }

    func load(with delegate: PlaylistViewModelDelegate) {
        self.delegate = delegate
    }
}
