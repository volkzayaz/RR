//
//  AuthorizationControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class AuthorizationControllerViewModel: AuthorizationViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AuthorizationViewModelDelegate?
    private(set) weak var router: AuthorizationRouter?

    // MARK: - Lifecycle -

    init(router: AuthorizationRouter) {
        self.router = router
    }

    func load(with delegate: AuthorizationViewModelDelegate) {
        self.delegate = delegate
    }

    func change(authorizationType: AuthorizationType) {
        self.router?.change(authorizationType: authorizationType)
    }
}
