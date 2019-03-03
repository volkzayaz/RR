//
//  ContriesSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Country: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol CountriesDataSource: class {

    var countries: [Country] { get }
    func reloadCountries(completion: @escaping (Result<[Country]>) -> Void)
}

class CountriesSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: CountriesDataSource

    typealias Item = Country

    var items: [Item] { return dataSource.countries }

    init(with dataSource: CountriesDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadCountries { (contriesResult) in

            switch contriesResult {
            case .success(let countries):
                completion(Result.success(countries))

            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func filterItems(items: [Item], with searchText: String) -> [Item] {
        guard searchText.isEmpty == false else { return items }
        return items.filter( {return $0.name.lowercased().contains(searchText.lowercased()) })
    }

    var isEditable: Bool { return false }
    
    func canAddItem(with name: String) -> Bool { return false }
    func addItem(with name: String) -> Country? { return nil }
}

final class ContriesSelectableListControllerViewModel: SelectableListControllerViewModel<CountriesSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = (Country) -> Void

    override var title: String { return NSLocalizedString("Select Country", comment: "Select Country Title") }

    var itemSelectionCallback: ItemSelectionCallback?
    

    init(router: SelectableListRouter, dataSource: CountriesDataSource, selectedItem: Country?, itemSelectionCallback: ItemSelectionCallback?) {

        var selectedItems: [Country] = [Country]()
        if let selectedItem = selectedItem {
            selectedItems.append(selectedItem)
        }

        super.init(router: router, dataProvider: CountriesSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems, isSearchable: true, selectionType: .single)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        if let selectedItem = self.selectedItems.first {
            self.itemSelectionCallback?(selectedItem)
        }

        super.done()
    }
}
