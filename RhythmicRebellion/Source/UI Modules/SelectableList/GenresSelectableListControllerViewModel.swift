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

    var identifier: String { return String(self.id) }
    var title: String { return self.name }
}

protocol GenresDataSource: class {

    var genres: [Genre] { get }
    func reloadGenres(completion: @escaping (Result<[Genre]>) -> Void)
}

class GenresSelectableListItemsDataProvider: SelectableListItemsDataProvider {

    var dataSource: GenresDataSource

    typealias Item = Genre

    var items: [Item] { return dataSource.genres }

    init(with dataSource: GenresDataSource) {
        self.dataSource = dataSource
    }

    func reload(completion: @escaping (Result<[Item]>) -> Void) {
        self.dataSource.reloadGenres { (genresResult) in

            switch genresResult {
            case .success(let genres):
                completion(Result.success(genres))

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

final class GenresSelectableListControllerViewModel: SelectableListControllerViewModel<GenresSelectableListItemsDataProvider> {

    typealias ItemsSelectionCallback = ([Genre]) -> Void

    override var title: String { return NSLocalizedString("Select Genres", comment: "Select Genres Title") }

    var itemsSelectionCallback: ItemsSelectionCallback?


    init(router: SelectableListRouter, dataSource: GenresDataSource, selectedItems: [Genre]?, itemsSelectionCallback: ItemsSelectionCallback?) {

        super.init(router: router, dataProvider: GenresSelectableListItemsDataProvider(with: dataSource), selectedItems: selectedItems ?? [], isSearchable: true, selectionType: .multiple)

        self.itemsSelectionCallback = itemsSelectionCallback
    }

    override func done() {

        self.itemsSelectionCallback?(self.selectedItems)

        super.done()
    }
}
