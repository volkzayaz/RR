//
//  ChangeEmailControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class ChangeEmailControllerViewModel: ChangeEmailViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: ChangeEmailViewModelDelegate?
    private(set) weak var router: ChangeEmailRouter?

    // MARK: - Lifecycle -

    init(router: ChangeEmailRouter) {
        self.router = router
    }

    func load(with delegate: ChangeEmailViewModelDelegate) {
        self.delegate = delegate
    }
}
