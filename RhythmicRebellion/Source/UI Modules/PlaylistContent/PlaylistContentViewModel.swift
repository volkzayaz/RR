//
//  PlaylistContentViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistContentViewModel: class {

    var playlistHeaderViewModel: PlaylistHeaderViewModel { get }

    func load(with delegate: PlaylistContentViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> TrackItemViewModel?
    func actions(forObjectAt: IndexPath) -> TrackActionsViewModels.ViewModel?
}

protocol PlaylistContentViewModelDelegate: class, ErrorPresnting {

    func refreshUI()
    func reloadUI()
}
