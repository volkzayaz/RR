//
//  PageContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PageContentControllerViewModel: PageContentViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PageContentViewModelDelegate?
    private(set) weak var router: PageContentRouter?

    private(set) var pagesLocalStorage: PagesLocalStorageService

    private(set) var page: Page
    var url: URL? { return page.url }
    var snapshotImage: UIImage? { return self.pagesLocalStorage.snapshotImage(for: self.page) }
    var isNeedUpdateSnapshotImage: Bool { return self.pagesLocalStorage.containsSnapshotImage(for: self.page) == false }

    // MARK: - Lifecycle -

    init(router: PageContentRouter, page: Page, pagesLocalStorage: PagesLocalStorageService) {
        self.router = router
        self.page = page
        self.pagesLocalStorage = pagesLocalStorage
    }

    func load(with delegate: PageContentViewModelDelegate) {
        self.delegate = delegate

        self.delegate?.reloadUI()
    }

    func save(snapshotImage: UIImage) {
        self.pagesLocalStorage.save(snapshotImage: snapshotImage, for: self.page)
    }

}
