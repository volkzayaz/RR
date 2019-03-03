//
//  TabBarViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol TabBarViewModel: class {

    func load(with delegate: TabBarViewModelDelegate)

}

protocol TabBarViewModelDelegate: class {

    func refreshUI()

}
