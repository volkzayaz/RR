//
//  GeneresSelectableListControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Genre: SelectableListItem {

    var identifier: String { return String(self.hashValue) }
    var title: String { return self.name }
}

protocol GenresDataSource: class {

    var genres: [Genre] { get }
    func reloadGenres(completion: @escaping (Result<[Genre]>) -> Void)
}

class GenresSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: GenresDataSource

    typealias Item = Genre

    var items: [Item]

    private var additionalItems: [Item]

    init(with dataSource: GenresDataSource, additionalItems: [Item]?) {
        self.dataSource = dataSource
        self.additionalItems = additionalItems ?? []

        self.items = self.dataSource.genres
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadGenres { (genresResult) in

            switch genresResult {
            case .success(let genres):
                self.items = genres

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
        let genre = Genre(with: name)
        self.items.append(genre)
        self.additionalItems.append(genre)

        return genre
    }

}

final class GenresSelectableListControllerViewModel: SelectableListControllerViewModel<GenresSelectableListItemsDataProvider> {

    typealias ItemsSelectionCallback = ([Genre]) -> Void

    override var title: String { return NSLocalizedString("Select Genres", comment: "Select Genres Title") }

    var itemsSelectionCallback: ItemsSelectionCallback?


    init(router: SelectableListRouter, dataSource: GenresDataSource, selectedItems: [Genre]?, additionalItems: [Genre]?, itemsSelectionCallback: ItemsSelectionCallback?) {

        super.init(router: router, dataProvider: GenresSelectableListItemsDataProvider(with: dataSource, additionalItems: additionalItems), selectedItems: selectedItems ?? [], isSearchable: true, selectionType: .multiple)

        self.itemsSelectionCallback = itemsSelectionCallback
    }

    override func done() {

        self.itemsSelectionCallback?(Array(self.selectedItems))

        super.done()
    }
}
