//
//  ChangeEmailViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ChangeEmailViewModel: class {

    func load(with delegate: ChangeEmailViewModelDelegate)

}

protocol ChangeEmailViewModelDelegate: class {

    func refreshUI()

}
