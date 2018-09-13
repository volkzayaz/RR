//
//  LanguagesSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/13/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Language: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol LanguagesDataSource: class {

    var languages: [Language] { get }
    func reloadLanguages(completion: @escaping (Result<[Language]>) -> Void)
}

class LanguagesSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: LanguagesDataSource

    typealias Item = Language

    var items: [Item] { return dataSource.languages }

    init(with dataSource: LanguagesDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadLanguages { (languagesResult) in

            switch languagesResult {
            case .success(let languages):
                completion(Result.success(languages))

            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func filterItems(items: [Item], with searchText: String) -> [Item] {
        guard searchText.isEmpty == false else { return items }
        return items.filter( {return $0.name.lowercased().contains(searchText.lowercased()) })
    }
}

final class LanguagesSelectableListControllerViewModel: SelectableListControllerViewModel<LanguagesSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = (Language) -> Void

    override var title: String { return NSLocalizedString("Select City", comment: "Select City Title") }

    var itemSelectionCallback: ItemSelectionCallback?


    init(router: SelectableListRouter, dataSource: LanguagesDataSource, selectedItem: Language?, itemSelectionCallback: ItemSelectionCallback?) {

        var selectedItems: [Language] = []
        if let selectedItem = selectedItem {
            selectedItems.append(selectedItem)
        }

        super.init(router: router, dataProvider:  LanguagesSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems, isSearchable: false, selectionType: .single)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        if let selectedItem = self.selectedItems.first {
            self.itemSelectionCallback?(selectedItem)
        }

        super.done()
    }
}
