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
    private(set) weak var application: Application?

    // MARK: - Lifecycle -

    init(router: ProfileRouter, application: Application) {
        self.router = router
        self.application = application
    }

    func load(with delegate: ProfileViewModelDelegate) {
        self.delegate = delegate
    }

    // MARK: - Actions
    func logout() {
        self.application?.logout()
    }
}
