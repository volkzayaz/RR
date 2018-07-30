//
//  FollowViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol FollowViewModel: class {

    func load(with delegate: FollowViewModelDelegate)

}

protocol FollowViewModelDelegate: class {

    func refreshUI()

}
