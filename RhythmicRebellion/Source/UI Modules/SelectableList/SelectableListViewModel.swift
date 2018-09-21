//
//  SelectableListViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum SelectionType {
    case single
    case multiple
}

protocol SelectableListItemViewModel {
    var name: String { get }
}

protocol SelectableListViewModel: class {

    var title: String { get }
    var doneButtonTitle: String { get }

    var canDone: Bool { get }

    var isSearchable: Bool { get }
    var selectionType: SelectionType { get }

    func load(with delegate: SelectableListViewModelDelegate)

    func reload()

    func filterItems(with searchText: String)

    func numberOfSections() -> Int
    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> SelectableListItemViewModel?

    func selectObject(at indexPath: IndexPath)

    func done()
}

protocol SelectableListViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func reloadUI()
    func reloadItems(at indexPaths: [IndexPath])
}
