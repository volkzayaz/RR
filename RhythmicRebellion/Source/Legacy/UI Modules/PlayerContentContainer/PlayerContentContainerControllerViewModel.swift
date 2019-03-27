//
//  PlayerContentContainerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerContentContainerControllerViewModel: PlayerContentContainerViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerContentContainerViewModelDelegate?
    private(set) weak var router: PlayerContentContainerRouter?

    // MARK: - Lifecycle -

    init(router: PlayerContentContainerRouter) {
        self.router = router
    }

    func load(with delegate: PlayerContentContainerViewModelDelegate) {
        self.delegate = delegate
    }
}
