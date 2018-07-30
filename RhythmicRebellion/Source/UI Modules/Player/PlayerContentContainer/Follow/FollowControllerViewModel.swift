//
//  FollowControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class FollowControllerViewModel: FollowViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: FollowViewModelDelegate?
    private(set) weak var router: FollowRouter?

    // MARK: - Lifecycle -

    init(router: FollowRouter) {
        self.router = router
    }

    func load(with delegate: FollowViewModelDelegate) {
        self.delegate = delegate
    }
}
