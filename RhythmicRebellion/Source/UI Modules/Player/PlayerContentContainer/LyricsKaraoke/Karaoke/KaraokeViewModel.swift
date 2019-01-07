//
//  KaraokeViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum KaraokeViewMode: Int {
    case scroll
    case onePhrase
}

protocol KaraokeViewModel: class {

    var viewMode: KaraokeViewMode { get }
    var currentItemIndexPath: IndexPath? { get }

    func load(with delegate: KaraokeViewModelDelegate)

    func thumbnailURL() -> URL?

    func numberOfItems(in section: Int) -> Int
    func item(at indexPath: IndexPath) -> DefaultKaraokeIntervalViewModel?
    func itemViewHeight(at indexPath: IndexPath, with width: CGFloat) -> CGFloat

    func change(viewMode: KaraokeViewMode)


    func switchToLyrics()

}

protocol KaraokeViewModelDelegate: class {

    func reloadUI()
    func refreshUI()

}
