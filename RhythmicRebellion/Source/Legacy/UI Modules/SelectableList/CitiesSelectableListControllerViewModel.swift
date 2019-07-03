//
//  CitiesSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension City: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol CitiesDataSource: class {

    var cities: [City] { get }
    func reloadCities(completion: @escaping (Result<[City]>) -> Void)
}

class CitiesSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: CitiesDataSource

    typealias Item = City

    var items: [Item] { return dataSource.cities }

    init(with dataSource: CitiesDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadCities { (citiesResult) in

            switch citiesResult {
            case .success(let cities):
                completion(Result.success(cities))

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
    func addItem(with name: String) -> City? { return nil }
}

final class CitiesSelectableListControllerViewModel: SelectableListControllerViewModel<CitiesSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = (City) -> Void

    override var title: String { return "Select City" }

    var itemSelectionCallback: ItemSelectionCallback?


    init(router: SelectableListRouter, dataSource: CitiesDataSource, selectedItem: City?, itemSelectionCallback: ItemSelectionCallback?) {

        var selectedItems: [City] = [City]()
        if let selectedItem = selectedItem {
            selectedItems.append(selectedItem)
        }

        super.init(router: router, dataProvider:  CitiesSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems, isSearchable: true, selectionType: .single)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        if let selectedItem = self.selectedItems.first {
            self.itemSelectionCallback?(selectedItem)
        }

        super.done()
    }
}
