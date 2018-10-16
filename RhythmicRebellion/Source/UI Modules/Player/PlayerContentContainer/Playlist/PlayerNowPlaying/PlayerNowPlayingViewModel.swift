//
//  PlayerNowPlayingViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerNowPlayingViewModel: class {

    func load(with delegate: PlayerNowPlayingViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> TrackViewModel?
    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel?
    
    func selectObject(at indexPath: IndexPath)
    func perform(action : PlayerNowPlayingTableHeaderView.Actions)

    func downloadObject(at indexPath: IndexPath)
    func cancelDownloadingObject(at indexPath: IndexPath)
    func objectLoaclURL(at indexPath: IndexPath) -> URL?
}

protocol PlayerNowPlayingViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func reloadUI()

    func reloadObjects(at indexPaths: [IndexPath])

}
