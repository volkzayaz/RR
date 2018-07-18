//
//  ProfileControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class ProfileControllerViewModel: ProfileViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: ProfileViewModelDelegate?
    private(set) weak var router: ProfileRouter?

    // MARK: - Lifecycle -

    init(router: ProfileRouter) {
        self.router = router
    }

    func load(with delegate: ProfileViewModelDelegate) {
        self.delegate = delegate
    }
}
