//
//  HomeViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol HomeViewModel: class {

    func load(with delegate: HomeViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> PlaylistItemViewModel?
    func selectObject(at indexPath: IndexPath)

}

protocol HomeViewModelDelegate: class, ErrorPresnting {

    func refreshUI()
    func reloadUI()
}
