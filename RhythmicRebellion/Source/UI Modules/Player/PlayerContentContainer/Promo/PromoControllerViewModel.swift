//
//  PromoControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PromoControllerViewModel: PromoViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PromoViewModelDelegate?
    private(set) weak var router: PromoRouter?

    // MARK: - Lifecycle -

    init(router: PromoRouter) {
        self.router = router
    }

    func load(with delegate: PromoViewModelDelegate) {
        self.delegate = delegate
    }
}
