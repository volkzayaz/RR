//
//  HowHearSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/7/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension HowHear: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol HowHearListDataSource: class {

    var howHearList: [HowHear] { get }
    func reloadHowHearList(completion: @escaping (Result<[HowHear]>) -> Void)
}

class HowHearSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: HowHearListDataSource

    typealias Item = HowHear

    var items: [Item] { return dataSource.howHearList }

    init(with dataSource: HowHearListDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadHowHearList { (howHearListResult) in

            switch howHearListResult {
            case .success(let howHearList):
                completion(Result.success(howHearList))

            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func filterItems(items: [Item], with searchText: String) -> [Item] {
        guard searchText.isEmpty == false else { return items }
        return items.filter( {return $0.name.lowercased().starts(with: searchText.lowercased()) })
    }
}

final class HowHearSelectableListControllerViewModel: SelectableListControllerViewModel<HowHearSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = (HowHear) -> Void

    override var title: String { return NSLocalizedString("Select How Hear", comment: "Select How Hear Title") }

    var itemSelectionCallback: ItemSelectionCallback?


    init(router: SelectableListRouter, dataSource: HowHearListDataSource, selectedItem: HowHear?, itemSelectionCallback: ItemSelectionCallback?) {

        var selectedItems: [HowHear] = [HowHear]()
        if let selectedItem = selectedItem {
            selectedItems.append(selectedItem)
        }

        super.init(router: router, dataProvider:  HowHearSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems, isSearchable: false, selectionType: .single)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        if let selectedItem = self.selectedItems.first {
            self.itemSelectionCallback?(selectedItem)
        }

        super.done()
    }
}

