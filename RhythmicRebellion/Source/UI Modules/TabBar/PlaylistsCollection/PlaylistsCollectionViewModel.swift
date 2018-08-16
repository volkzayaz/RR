//
//  PlaylistsCollectionViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistsCollectionViewModel: class {

    func load(with delegate: PlaylistsCollectionViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> PlaylistItemCollectionViewCellViewModel?
    func selectObject(at indexPath: IndexPath)
}

protocol PlaylistsCollectionViewModelDelegate: class, ErrorPresnting {

    func refreshUI()
    func reloadUI()
}