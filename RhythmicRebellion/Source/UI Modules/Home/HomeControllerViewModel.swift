//
//  HomeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class HomeControllerViewModel: HomeViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: HomeViewModelDelegate?
    private(set) weak var router: HomeRouter?

    // MARK: - Lifecycle -

    init(router: HomeRouter) {
        self.router = router
    }

    func load(with delegate: HomeViewModelDelegate) {
        self.delegate = delegate
    }
}
