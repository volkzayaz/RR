//
//  SelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Alamofire


protocol SelectableListItem: Hashable {
    var identifier: String { get }
    var title: String { get }
}

protocol SelectableListItemsDataProvider {

    associatedtype Item: SelectableListItem

    var items: [Item] { get }
    func reload(completion: @escaping (Result<[Item]>) -> Void)
    func filterItems(items: [Item], with searchText: String) -> [Item]
}

class SelectableListControllerViewModel<T: SelectableListItemsDataProvider>: SelectableListViewModel {

    var title: String { return "" }
    var doneButtonTitle: String { return NSLocalizedString("Done", comment: "Done BarButton ttile") }

    var isSearchable: Bool
    var canDone: Bool { return self.initialSelectedItems != Set(self.selectedItems) }

    private(set) weak var delegate: SelectableListViewModelDelegate?
    private(set) weak var router: SelectableListRouter?

    private(set) var dataProvider: T

    private(set) var filteredItems: [T.Item]
    private(set) var initialSelectedItems: Set<T.Item>
    private(set) var selectedItems: [T.Item]

    private(set) var selectionType: SelectionType

    private(set) var searchText: String = ""

    // MARK: - Lifecycle -

    init(router: SelectableListRouter, dataProvider: T, selectedItems: [T.Item], isSearchable: Bool, selectionType: SelectionType) {
        self.router = router
        self.dataProvider = dataProvider
        self.selectionType = selectionType
        self.isSearchable = isSearchable

        self.filteredItems = dataProvider.items
        self.initialSelectedItems = Set(selectedItems)
        self.selectedItems = selectedItems
    }

    func load(with delegate: SelectableListViewModelDelegate) {
        self.delegate = delegate

        if self.dataProvider.items.count == 0 {
            self.reload()
        }

        self.filteredItems = self.dataProvider.items

        self.delegate?.reloadUI()
    }

    func reload() {
        self.dataProvider.reload { [weak self] (itemsResult) in
            guard let `self` = self else { return }

            switch itemsResult {
            case .success(let items):
                self.selectedItems = self.selectedItems.filter( { return items.contains($0)} )
                self.filteredItems = self.dataProvider.filterItems(items: items, with: self.searchText)
                self.delegate?.reloadUI()
            case .failure(let error):
                self.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            }
        }
    }

    func filterItems(with searchText: String) {
        self.searchText = searchText
        self.filteredItems = self.dataProvider.filterItems(items: self.dataProvider.items, with: self.searchText)
        self.delegate?.reloadUI()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.filteredItems.count
    }

    func object(at indexPath: IndexPath) -> SelectableListItemViewModel? {
        guard self.filteredItems.count > indexPath.row else { return nil }

        let selectableListItem = self.filteredItems[indexPath.row]

        return SelectableListItemViewModel(with: selectableListItem, isSelected: self.selectedItems.contains(selectableListItem))

    }

    func selectObject(at indexPath: IndexPath) {
        guard self.filteredItems.count > indexPath.row else { return }

        let selectableListItem = self.filteredItems[indexPath.row]

        switch self.selectionType {
        case .single:
            var indexPathsToReload = self.selectedItems.compactMap { (selectableListItem) -> IndexPath? in
                guard let selectedItemIndex = self.filteredItems.index(of: selectableListItem) else { return nil }
                return IndexPath(row: selectedItemIndex, section: indexPath.section)
            }
            self.selectedItems.removeAll()

            self.selectedItems.append(selectableListItem)
            indexPathsToReload.append(indexPath)

            self.delegate?.reloadItems(at: indexPathsToReload)
            self.done()
            break

        case .multiple:
            if let selectableListItemIndex = self.selectedItems.index(of: selectableListItem) {
                self.selectedItems.remove(at: selectableListItemIndex)
            } else {
                self.selectedItems.append(selectableListItem)
            }

            self.delegate?.reloadItems(at: [indexPath])
            break
        }

    }

    func done() {
        self.delegate?.refreshUI()
        self.router?.done()
    }
}

