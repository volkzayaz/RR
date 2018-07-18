//
//  HomeViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol HomeViewModel: class {

    func load(with delegate: HomeViewModelDelegate)

}

protocol HomeViewModelDelegate: class {

    func refreshUI()

}
