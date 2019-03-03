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

    var identifier: String { return String(self.hashValue) }
    var title: String { return self.name }
}

protocol HobbiesDataSource: class {

    var hobbies: [Hobby] { get }
    func reloadHobbies(completion: @escaping (Result<[Hobby]>) -> Void)
}

class HobbiesSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: HobbiesDataSource

    typealias Item = Hobby

    var items: [Item]

    private var additionalItems: [Item]

    init(with dataSource: HobbiesDataSource, additionalItems: [Item]?) {
        self.dataSource = dataSource
        self.additionalItems = additionalItems ?? []

        self.items = self.dataSource.hobbies
//        self.items.append(contentsOf: self.additionalItems)
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadHobbies { (hobbiesResult) in

            switch hobbiesResult {
            case .success(let hobbies):
                self.items = hobbies
//                self.items.append(contentsOf: self.additionalItems)

                completion(Result.success(self.items))

            case .failure(let error):
                completion(Result.failure(error))
            }
        }
    }

    func filterItems(items: [Item], with searchText: String) -> [Item] {
        guard searchText.isEmpty == false else { return items }
        return items.filter( {return $0.name.lowercased().contains(searchText.lowercased()) })
    }

    var isEditable: Bool { return true }

    func canAddItem(with name: String) -> Bool {
        guard self.isEditable == true else { return false }
        guard self.items.count > 0 else { return false }
        guard name.isEmpty == false else { return false }

        let filteredAdditionalItems = self.additionalItems.filter { $0.name.lowercased() == name.lowercased() }

        return filteredAdditionalItems.isEmpty
    }

    func addItem(with name: String) -> Item? {
        let hobby = Hobby(with: name)
        self.items.append(hobby)
        self.additionalItems.append(hobby)

        return hobby
    }

}

final class HobbiesSelectableListControllerViewModel: SelectableListControllerViewModel<HobbiesSelectableListItemsDataProvider> {

    typealias ItemsSelectionCallback = ([Hobby]) -> Void

    override var title: String { return NSLocalizedString("Select Hobbies", comment: "Select Hobbies Title") }

    var itemsSelectionCallback: ItemsSelectionCallback?


    init(router: SelectableListRouter, dataSource: HobbiesDataSource, selectedItems: [Hobby]?, additionalItems: [Hobby]?, itemsSelectionCallback: ItemsSelectionCallback?) {

        super.init(router: router, dataProvider:  HobbiesSelectableListItemsDataProvider(with: dataSource, additionalItems: additionalItems), selectedItems: selectedItems ?? [], isSearchable: true, selectionType: .multiple)

        self.itemsSelectionCallback = itemsSelectionCallback
    }

    override func done() {

        self.itemsSelectionCallback?(Array(self.selectedItems))

        super.done()
    }
}
