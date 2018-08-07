//
//  PlayerFollowingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerFollowingControllerViewModel: PlayerFollowingViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerFollowingViewModelDelegate?
    private(set) weak var router: PlayerFollowingRouter?

    // MARK: - Lifecycle -

    init(router: PlayerFollowingRouter) {
        self.router = router
    }

    func load(with delegate: PlayerFollowingViewModelDelegate) {
        self.delegate = delegate
    }
}
