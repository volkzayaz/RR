//
//  PlayerPlaylistRootViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerPlaylistRootViewModel: class {

    func load(with delegate: PlayerPlaylistRootViewModelDelegate)
    var showOnlyNowPlaying : Bool { get }
}

protocol PlayerPlaylistRootViewModelDelegate: class {

    func refreshUI()

}
