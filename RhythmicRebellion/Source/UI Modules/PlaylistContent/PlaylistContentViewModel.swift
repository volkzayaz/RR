//
//  PlaylistContentViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlaylistContentViewModel: class {

    var playlistHeaderViewModel: PlaylistHeaderViewModel { get }

    func load(with delegate: PlaylistContentViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> TrackViewModel?
    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel?
    func selectObject(at indexPath: IndexPath)

    func downloadObject(at indexPath: IndexPath)
    func cancelDownloadingObject(at indexPath: IndexPath)
}

protocol PlaylistContentViewModelDelegate: class, ErrorPresenting {

    func refreshUI()
    func reloadUI()

    func reloadObjects(at indexPaths: [IndexPath])
}
