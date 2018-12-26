//
//  PagesLocalStorageService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol PagesLocalStorageServiceWatcher: class {
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didAdd page: Page)
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didUpdate page: Page)
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didDelete page: Page)

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didSaveSnapshotImageFor page: Page)
}

extension PagesLocalStorageServiceWatcher {
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didAdd page: Page) { }
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didUpdate page: Page) { }
    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didDelete page: Page) { }

    func pagesLocalStorageService(_ pagesLocalStorageService: PagesLocalStorageService, didSaveSnapshotImageFor page: Page) { }
}


class PagesLocalStorageService: Watchable {

    typealias WatchType = PagesLocalStorageServiceWatcher
    let watchersContainer = WatchersContainer<WatchType>()

    var pageSnapshotAspectRatio: CGFloat = 1.4125


    private lazy var directoryURL: URL = {
        let applicationSupportDirectoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectoryURL.appendingPathComponent("PagesLocalStorage", isDirectory: true)
    }()

    private lazy var fileURL: URL = {
        return directoryURL.appendingPathComponent("PagesLocalStorage.plist")
    }()

    private lazy var imageCacheDirectiryURL: URL = {
        return self.directoryURL.appendingPathComponent("ImageCache", isDirectory: true)
    }()


    private(set) var pages: [Page]

    init() {

        self.pages = []
        self.load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: self.fileURL)
            self.pages = try PropertyListDecoder().decode([Page].self, from: data)
        } catch {
            print("PagesLocalStorageService loading error: \(error)")
        }
    }

    func save() {
        do {
            let data = try PropertyListEncoder().encode(self.pages)
            let fileManager = FileManager.default

            if fileManager.fileExists(atPath: self.fileURL.path, isDirectory: nil) == false {
                try fileManager.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            } else {
                try fileManager.removeItem(at: self.fileURL)
            }
            try data.write(to: self.fileURL, options: [])

        } catch {
            print("PagesLocalStorageService saving error: \(error)")
        }
    }

    func reset() {
        guard self.pages.isEmpty == false else { return }

        do {
            let contentsOfDirectory = try FileManager.default.contentsOfDirectory(at: self.imageCacheDirectiryURL, includingPropertiesForKeys: nil)

            try contentsOfDirectory.forEach { (itemURL) in
                try FileManager.default.removeItem(at: itemURL)
            }
        } catch {
            print("Can't clear imageCacheDirectiryURL")
        }

        self.pages.removeAll()
        self.save()
    }

    func snapshotImageURL(for page: Page) -> URL {

        let md5 = page.urlString.MD5()

        return self.imageCacheDirectiryURL.appendingPathComponent(md5 + ".png")
    }

    func page(for url: URL) -> Page? {
        return self.pages.filter { $0.url == url }.first
    }

    func containsPage(with url: URL) -> Bool {
        return self.page(for: url) != nil 
    }

    func add(page: Page) {
        guard self.pages.index(of: page) == nil else { return }

        self.pages.append(page)
        self.save()

        self.watchersContainer.invoke { (observer) in
            observer.pagesLocalStorageService(self, didAdd: page)
        }
    }

    func update(page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }

        self.pages[pageIndex] = page
        self.save()

        self.watchersContainer.invoke { (observer) in
            observer.pagesLocalStorageService(self, didUpdate: page)
        }
    }

    func delete(page: Page) {
        guard let pageIndex = self.pages.index(of: page) else { return }


        do {
            try FileManager.default.removeItem(at: self.snapshotImageURL(for: page))
        } catch {
            print("PagesLocalStorageService delete snapshotImage error: \(error)")
        }

        self.pages.remove(at: pageIndex)
        self.save()

        self.watchersContainer.invoke { (observer) in
            observer.pagesLocalStorageService(self, didDelete: page)
        }
    }

    func containsSnapshotImage(for page: Page) -> Bool {
        return FileManager.default.fileExists(atPath: self.snapshotImageURL(for: page).path)
    }

    func snapshotImage(for page: Page) -> UIImage? {
        let snapshotImageURL = self.snapshotImageURL(for: page)
        guard FileManager.default.fileExists(atPath: snapshotImageURL.path) else {
            return UIImage(named: "PagePlaceholder")
        }

        return UIImage(contentsOfFile: snapshotImageURL.path)
    }

    func save(snapshotImage: UIImage, for page: Page) {
        guard let imageData = snapshotImage.pngData() else { return }

        let snapshotImageURL = self.snapshotImageURL(for: page)
        let fileManager = FileManager.default

        do {
            if fileManager.fileExists(atPath: snapshotImageURL.path) == false {
                if fileManager.fileExists(atPath: self.imageCacheDirectiryURL.path, isDirectory: nil) == false {
                    try fileManager.createDirectory(at: self.imageCacheDirectiryURL, withIntermediateDirectories: true, attributes: nil)
                }
            } else {
                try fileManager.removeItem(at: snapshotImageURL)
            }

            try imageData.write(to: snapshotImageURL)

            self.watchersContainer.invoke { (observer) in
                observer.pagesLocalStorageService(self, didSaveSnapshotImageFor: page)
            }
        } catch {
            print("PagesLocalStorageService saving snapshotImage error: \(error)")
        }

    }
}
