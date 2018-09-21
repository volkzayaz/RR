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
    var name: String { get }
}

protocol SelectableListItemsDataProvider {

    associatedtype Item: SelectableListItem

    var items: [Item] { get }
    func reload(completion: @escaping (Result<[Item]>) -> Void)
    func filterItems(items: [Item], with searchText: String) -> [Item]

    var isEditable: Bool { get }
    func addItem(with name: String) -> Item?
}

class SelectableListControllerViewModel<T: SelectableListItemsDataProvider>: SelectableListViewModel {

    enum Section: Int {
        case items
        case addNewItem
    }

    var title: String { return "" }
    var doneButtonTitle: String { return NSLocalizedString("Done", comment: "Done BarButton ttile") }

    private(set) var isSearchable: Bool
    var canDone: Bool { return self.initialSelectedItems != Set(self.selectedItems) }

    private(set) weak var delegate: SelectableListViewModelDelegate?
    private(set) weak var router: SelectableListRouter?

    private(set) var dataProvider: T

    private(set) var filteredItems: [T.Item]
    private(set) var initialSelectedItems: Set<T.Item>
    private(set) var selectedItems: Set<T.Item>

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
        self.selectedItems = Set(selectedItems)
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

    func numberOfSections() -> Int {
        return self.dataProvider.isEditable ? 2 : 1
    }

    func numberOfItems(in section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .items: return self.filteredItems.count
        case .addNewItem:
            return self.filteredItems.isEmpty &&
                    !self.dataProvider.items.isEmpty &&
                    !self.searchText.isEmpty ? 1 : 0
        }
    }

    func object(at indexPath: IndexPath) -> SelectableListItemViewModel? {
        guard let section = Section(rawValue: indexPath.section) else { return nil }

        switch section {
        case .items:
            guard self.filteredItems.count > indexPath.row else { return nil }
            let selectableListItem = self.filteredItems[indexPath.row]
            return DefaultSelectableListItemViewModel(with: selectableListItem, isSelected: self.selectedItems.contains(selectableListItem))

        case .addNewItem:
            return AddNewSelectableListItemViewModel(name: "\"" + self.searchText + "\"")
        }
    }

    private func selectItem(at indexPath: IndexPath) {
        guard self.filteredItems.count > indexPath.row else { return }

        let selectableListItem = self.filteredItems[indexPath.row]

        switch self.selectionType {
        case .single:
            var indexPathsToReload = self.selectedItems.compactMap { (selectableListItem) -> IndexPath? in
                guard let selectedItemIndex = self.filteredItems.index(of: selectableListItem) else { return nil }
                return IndexPath(row: selectedItemIndex, section: indexPath.section)
            }
            self.selectedItems.removeAll()

            self.selectedItems.insert(selectableListItem)
            indexPathsToReload.append(indexPath)

            self.delegate?.reloadItems(at: indexPathsToReload)
            self.done()
            break

        case .multiple:
            if let selectableListItemIndex = self.selectedItems.index(of: selectableListItem) {
                self.selectedItems.remove(at: selectableListItemIndex)
            } else {
                self.selectedItems.insert(selectableListItem)
            }

            self.delegate?.reloadItems(at: [indexPath])
            break
        }
    }

    func selectObject(at indexPath: IndexPath) {

        guard let section = Section(rawValue: indexPath.section) else { return }

        switch section {
        case .items: self.selectItem(at: indexPath)

        case .addNewItem:
            guard let newItem = self.dataProvider.addItem(with: self.searchText) else { return }
            self.selectedItems.insert(newItem)
            self.filteredItems = self.dataProvider.filterItems(items: self.dataProvider.items, with: self.searchText)
            self.delegate?.reloadUI()
        }

    }

    func done() {
        self.delegate?.refreshUI()
        self.router?.done()
    }
}

