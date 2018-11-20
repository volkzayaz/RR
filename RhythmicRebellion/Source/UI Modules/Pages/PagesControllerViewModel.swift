//
//  PagesControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PagesControllerViewModel: PagesViewModel {

    var selectedIndexPath: IndexPath?

    // MARK: - Private properties -

    private(set) weak var delegate: PagesViewModelDelegate?
    private(set) weak var router: PagesRouter?

    private(set) var pagesLocalStorage: PagesLocalStorageService

    private var pages: [Page] { return self.pagesLocalStorage.pages }

    // MARK: - Lifecycle -

    deinit {
        self.pagesLocalStorage.removeObserver(self)
    }

    init(router: PagesRouter, pagesLocalStorage: PagesLocalStorageService) {
        self.router = router
        self.pagesLocalStorage = pagesLocalStorage
    }

    func load(with delegate: PagesViewModelDelegate) {
        self.delegate = delegate

        self.pagesLocalStorage.addObserver(self)

        self.delegate?.reloadUI()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.pages.count
    }

    func object(at indexPath: IndexPath) -> PageItemViewModel? {
        guard indexPath.item < self.pages.count else { return nil }

        let page = self.pages[indexPath.item]

        return PageItemViewModel(page: page, image: self.pagesLocalStorage.snapshotImage(for: page))
    }

    func selectObject(at indexPath: IndexPath) {
        guard indexPath.item < self.pages.count else { return }

        let page = self.pages[indexPath.item]

        self.selectedIndexPath = indexPath

        self.router?.navigate(to: page, animated: true)
    }

    func indexPath(for page: Page) -> IndexPath? {
        guard let pageIndex = self.pages.index(of: page) else { return nil }

        return IndexPath(item: pageIndex, section: 0)
    }

    func navigateToPage(with url: URL) {
        guard let page = self.pagesLocalStorage.page(for: url) else {
            let page = Page(url: url)
            self.pagesLocalStorage.add(page: page)
            if let pageIndex = self.pages.index(of: page) {
                self.selectedIndexPath = IndexPath(item: pageIndex, section: 0)
            }
            self.router?.navigate(to: page, animated: false)
            return
        }

        if let pageIndex = self.pages.index(of: page) {
            self.selectedIndexPath = IndexPath(item: pageIndex, section: 0)
        }

        self.router?.navigate(to: page, animated: false)
    }
}

extension PagesControllerViewModel : PagesLocalStorageServiceObserver {

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didAdd page: Page) {
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didUpdate page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }

        self.delegate?.reloadItem(at: IndexPath(item: pageIndex, section: 0))
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didDelete page: Page) {
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didSaveSnapshotImageFor page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }

        self.delegate?.reloadItem(at: IndexPath(item: pageIndex, section: 0))
    }

}
