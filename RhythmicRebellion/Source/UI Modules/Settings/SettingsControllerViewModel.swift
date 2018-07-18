//
//  SettingsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class SettingsControllerViewModel: SettingsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: SettingsViewModelDelegate?
    private(set) weak var router: SettingsRouter?

    // MARK: - Lifecycle -

    init(router: SettingsRouter) {
        self.router = router
    }

    func load(with delegate: SettingsViewModelDelegate) {
        self.delegate = delegate
    }
}
