//
//  PlayerMyPlaylistsViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerMyPlaylistsViewModel: class {

    func load(with delegate: PlayerMyPlaylistsViewModelDelegate)

}

protocol PlayerMyPlaylistsViewModelDelegate: class {

    func refreshUI()

}
