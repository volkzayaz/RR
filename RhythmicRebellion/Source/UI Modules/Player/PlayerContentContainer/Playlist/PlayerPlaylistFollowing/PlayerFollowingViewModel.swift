//
//  PlayerFollowingViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerFollowingViewModel: class {

    func load(with delegate: PlayerFollowingViewModelDelegate)

}

protocol PlayerFollowingViewModelDelegate: class {

    func refreshUI()

}
