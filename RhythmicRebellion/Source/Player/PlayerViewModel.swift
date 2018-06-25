//
//  PlayerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerViewModel: class {

    func load(with delegate: PlayerViewModelDelegate)

}

protocol PlayerViewModelDelegate: class {

    func refreshUI()

}
