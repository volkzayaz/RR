//
//  ApplicationContentContainerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class ApplicationContentContainerControllerViewModel: ApplicationContentContainerViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: ApplicationContentContainerViewModelDelegate?
    private(set) weak var router: ApplicationContentContainerRouter?

    // MARK: - Lifecycle -

    init(router: ApplicationContentContainerRouter) {
        self.router = router
    }

    func load(with delegate: ApplicationContentContainerViewModelDelegate) {
        self.delegate = delegate
    }
}
