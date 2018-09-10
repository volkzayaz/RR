//
//  RestorePasswordViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol RestorePasswordViewModel: class {

    func load(with delegate: RestorePasswordViewModelDelegate)

}

protocol RestorePasswordViewModelDelegate: class {

    func refreshUI()

}
