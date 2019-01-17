//
//  KaraokeViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol KaraokeViewModelProtocol: class, KaraokeCollectionViewFlowLayoutViewModel {

    var viewMode: KaraokeViewMode { get }
    var currentItemIndexPath: IndexPath? { get }

    var isVocalAudioFile: Bool { get }
    var canChangeAudioFileType: Bool { get }

    func load(with delegate: KaraokeViewModelDelegate)

    func thumbnailURL() -> URL?

    func numberOfItems(in section: Int) -> Int
    func item(at indexPath: IndexPath) -> DefaultKaraokeIntervalViewModel?

    func change(viewMode: KaraokeViewMode)
    func changeAudioFileType()

    func switchToLyrics()

}

protocol KaraokeViewModelDelegate: class {

    func reloadUI()
    func refreshUI()

}
