//
//  PlaylistViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistViewModel: class {

    func load(with delegate: PlaylistViewModelDelegate)

}

protocol PlaylistViewModelDelegate: class {

    func refreshUI()

}
