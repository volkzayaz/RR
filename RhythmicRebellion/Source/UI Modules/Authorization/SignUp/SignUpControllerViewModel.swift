//
//  SignUpControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class SignUpControllerViewModel: SignUpViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: SignUpViewModelDelegate?
    private(set) weak var router: SignUpRouter?

    // MARK: - Lifecycle -

    init(router: SignUpRouter) {
        self.router = router
    }

    func load(with delegate: SignUpViewModelDelegate) {
        self.delegate = delegate
    }
}
