//
//  PlayerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation


final class PlayerControllerViewModel: PlayerViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerViewModelDelegate?
    private(set) weak var router: PlayerRouter?

    // MARK: - Lifecycle -

    init(router: PlayerRouter) {
        self.router = router
    }

    func load(with delegate: PlayerViewModelDelegate) {
        self.delegate = delegate
    }
}
