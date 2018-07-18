//
//  PagesControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PagesControllerViewModel: PagesViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PagesViewModelDelegate?
    private(set) weak var router: PagesRouter?

    // MARK: - Lifecycle -

    init(router: PagesRouter) {
        self.router = router
    }

    func load(with delegate: PagesViewModelDelegate) {
        self.delegate = delegate
    }
}
