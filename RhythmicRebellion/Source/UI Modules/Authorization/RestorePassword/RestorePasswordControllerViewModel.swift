//
//  RestorePasswordControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class RestorePasswordControllerViewModel: RestorePasswordViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: RestorePasswordViewModelDelegate?
    private(set) weak var router: RestorePasswordRouter?

    // MARK: - Lifecycle -

    init(router: RestorePasswordRouter) {
        self.router = router
    }

    func load(with delegate: RestorePasswordViewModelDelegate) {
        self.delegate = delegate
    }
}
