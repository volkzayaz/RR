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
    func item(at indexPath: IndexPath) -> PageItemViewModel?
    func selectItem(at indexPath: IndexPath)
    func deleteItem(at indexPath: IndexPath)

    func indexPath(for page: Page) -> IndexPath?

    func navigateToPage(with url: URL)

    func show(error: Error)
}

protocol PagesViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func reloadUI()
}