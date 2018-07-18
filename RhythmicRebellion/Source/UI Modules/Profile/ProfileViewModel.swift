//
//  ProfileViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ProfileViewModel: class {

    func load(with delegate: ProfileViewModelDelegate)

}

protocol ProfileViewModelDelegate: class {

    func refreshUI()

}
