//
//  HobbiesSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/7/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Hobby: SelectableListItem {

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol HobbiesDataSource: class {

    var hobbies: [Hobby] { get }
    func reloadHobbies(completion: @escaping (Result<[Hobby]>) -> Void)
}

class HobbiesSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: HobbiesDataSource

    typealias Item = Hobby

    var items: [Item] { return dataSource.hobbies }

    init(with dataSource: HobbiesDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadHobbies { (hobbiesResult) in

            switch hobbiesResult {
            case .success(let hobbies):
                completion(Result.success(hobbies))

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

final class HobbiesSelectableListControllerViewModel: SelectableListControllerViewModel<HobbiesSelectableListItemsDataProvider> {

    typealias ItemSelectionCallback = ([Hobby]) -> Void

    override var title: String { return NSLocalizedString("Select City", comment: "Select City Title") }

    var itemSelectionCallback: ItemSelectionCallback?


    init(router: SelectableListRouter, dataSource: HobbiesDataSource, selectedItems: [Hobby]?, itemSelectionCallback: ItemSelectionCallback?) {

        super.init(router: router, dataProvider:  HobbiesSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems ?? [], isSearchable: true, selectionType: .multiple)

        self.itemSelectionCallback = itemSelectionCallback
    }

    override func done() {

        self.itemSelectionCallback?(self.selectedItems)

        super.done()
    }
}
