//
//  RegionsSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Region: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol RegionsDataSource: class {

    var regions: [Region] { get }
    func reloadRegions(completion: @escaping (Result<[Region]>) -> Void)
}

class RegionsSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: RegionsDataSource

    typealias Item = Region

    var items: [Item] { return dataSource.regions }

    init(with dataSource: RegionsDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadRegions { (regionsResult) in

            switch regionsResult {
            case .success(let regions):
                completion(Result.success(regions))

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


final class RegionsSelectableListControllerViewModel: SelectableListControllerViewModel<RegionsSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = (Region) -> Void

    override var title: String { return NSLocalizedString("Select State", comment: "Select State Title") }

    var itemSelectionCallback: ItemSelectionCallback?

    init(router: SelectableListRouter, dataSource: RegionsDataSource, selectedItem: Region?, itemSelectionCallback: ItemSelectionCallback?) {

        var selectedItems: [Region] = [Region]()
        if let selectedItem = selectedItem {
            selectedItems.append(selectedItem)
        }

        super.init(router: router, dataProvider: RegionsSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems, isSearchable: true, selectionType: .single)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        if let selectedItem = self.selectedItems.first {
            self.itemSelectionCallback?(selectedItem)
        }

        super.done()
    }
}
