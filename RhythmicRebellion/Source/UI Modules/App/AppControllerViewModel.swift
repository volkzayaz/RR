//
//  AppControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Reachability

final class AppControllerViewModel: AppViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AppViewModelDelegate?
    private(set) weak var router: AppRouter?

    private(set) weak var application: Application?

    var isPlayerDisclosed: Bool = false

    var user: User?

    // MARK: - Lifecycle -

    init(router: AppRouter, application: Application) {
        self.router = router
        self.application = application
    }

    func load(with delegate: AppViewModelDelegate) {
        self.delegate = delegate

        self.application?.start()
    }

    func togglePlayerDisclosure() {
        self.isPlayerDisclosed = !self.isPlayerDisclosed
        self.delegate?.playerDisclosureStateChanged(isDisclosed: self.isPlayerDisclosed)
    }
}
