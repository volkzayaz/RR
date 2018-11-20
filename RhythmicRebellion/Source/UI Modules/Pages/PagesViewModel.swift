//
//  PagesViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PagesViewModel: class {


    func load(with delegate: PagesViewModelDelegate)

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> PageItemViewModel?
    func selectObject(at indexPath: IndexPath)

    func indexPath(for page: Page) -> IndexPath?

    func navigateToPage(with url: URL)
}

protocol PagesViewModelDelegate: class {

    func refreshUI()
    func reloadUI()
    func reloadItem(at indexPath: IndexPath)
}
