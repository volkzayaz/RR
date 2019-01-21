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

    // MARK: - Private properties -

    private(set) weak var delegate: PagesViewModelDelegate?
    private(set) weak var router: PagesRouter?

    private(set) var pagesLocalStorage: PagesLocalStorageService

    private var pages: [Page]

    // MARK: - Lifecycle -

    deinit {
        self.pagesLocalStorage.removeWatcher(self)
    }

    init(router: PagesRouter, pagesLocalStorage: PagesLocalStorageService) {
        self.router = router
        self.pagesLocalStorage = pagesLocalStorage

        self.pages = []
    }

    func load(with delegate: PagesViewModelDelegate) {
        self.delegate = delegate

        self.pages = self.pagesLocalStorage.pages

        self.delegate?.reloadUI()
        self.pagesLocalStorage.addWatcher(self)
    }

    func numberOfItems(in section: Int) -> Int {
        return self.pages.count
    }

    func item(at indexPath: IndexPath) -> PageItemViewModel? {
        guard indexPath.item < self.pages.count else { return nil }

        let page = self.pages[indexPath.item]

        return PageItemViewModel(page: page, image: self.pagesLocalStorage.snapshotImage(for: page))
    }

    func selectItem(at indexPath: IndexPath) {
        guard indexPath.item < self.pages.count else { return }

        let page = self.pages[indexPath.item]

        self.router?.navigate(to: page, animated: true)
    }

    func deleteItem(at indexPath: IndexPath) {
        guard indexPath.item < self.pages.count else { return }

        let page = self.pages[indexPath.item]

        self.pagesLocalStorage.delete(page: page)
    }


    func indexPath(for page: Page) -> IndexPath? {
        guard let pageIndex = self.pages.index(of: page) else { return nil }

        return IndexPath(item: pageIndex, section: 0)
    }

    func navigateToPage(with url: URL) {
        guard let page = self.pagesLocalStorage.page(for: url) else {
            let page = Page(url: url)
            self.pagesLocalStorage.add(page: page)
            self.router?.navigate(to: page, animated: false)
            return
        }

        self.router?.navigate(to: page, animated: false)
    }

    func show(error: Error) {
        self.delegate?.show(error: error)
    }
}

extension PagesControllerViewModel : PagesLocalStorageServiceWatcher {

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didAdd page: Page) {
        self.pages.append(page)
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didUpdate page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }

        self.pages[pageIndex] = page
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didDelete page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }

        self.pages.remove(at: pageIndex)
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageServiceDidReset(_ pagesLocalStorageService: PagesLocalStorageService) {
        self.pages.removeAll()
        self.router?.navigateToPagesList(animated: false)
        self.delegate?.reloadUI()
    }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didSaveSnapshotImageFor page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }
        
        self.delegate?.reloadUI()
    }

}
