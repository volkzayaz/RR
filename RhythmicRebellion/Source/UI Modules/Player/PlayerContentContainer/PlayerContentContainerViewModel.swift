//
//  PlayerContentContainerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerContentContainerViewModel: class {

    func load(with delegate: PlayerContentContainerViewModelDelegate)

}

protocol PlayerContentContainerViewModelDelegate: class {

    func refreshUI()

}
