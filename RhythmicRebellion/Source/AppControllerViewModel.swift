//
//  AppControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class AppControllerViewModel: AppViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AppViewModelDelegate?
    private(set) weak var router: AppRouter?

    var isPlayerDisclosed: Bool = false

    // MARK: - Lifecycle -

    init(router: AppRouter) {
        self.router = router
    }

    func load(with delegate: AppViewModelDelegate) {
        self.delegate = delegate
    }

    func togglePlayerDisclosure() {
        self.isPlayerDisclosed = !self.isPlayerDisclosed
        self.delegate?.playerDisclosureStateChanged(isDisclosed: self.isPlayerDisclosed)
    }
}
