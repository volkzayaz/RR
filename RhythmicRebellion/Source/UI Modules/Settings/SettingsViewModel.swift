//
//  SettingsViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol SettingsViewModel: class {

    func load(with delegate: SettingsViewModelDelegate)

}

protocol SettingsViewModelDelegate: class {

    func refreshUI()

}
