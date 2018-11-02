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
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> PlaylistItemCollectionViewCellViewModel?
    func selectObject(at indexPath: IndexPath)

    func actions(forObjectAt indexPath: IndexPath) -> PlaylistActionsViewModels.ViewModel?
}

protocol PlayerMyPlaylistsViewModelDelegate: class, ErrorPresenting, AlertActionsViewModelPersenting, ConfirmationPresenting {

    func refreshUI()
    func reloadUI()
}
