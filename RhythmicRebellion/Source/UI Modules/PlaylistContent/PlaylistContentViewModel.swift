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

    var isPlaylistEmpty: Bool { get }
    var playlistHeaderViewModel: PlaylistHeaderViewModel { get }

    func load(with delegate: PlaylistContentViewModelDelegate)
    func reload()

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> TrackViewModel?

    func selectObject(at indexPath: IndexPath)

    func playlistActions() -> PlaylistActionsViewModels.ViewModel?
    func clearPlaylist()

    func actions(forObjectAt indexPath: IndexPath) -> AlertActionsViewModel<ActionViewModel>?

    func downloadObject(at indexPath: IndexPath)
    func cancelDownloadingObject(at indexPath: IndexPath)
    func objectLoaclURL(at indexPath: IndexPath) -> URL?
}

protocol PlaylistContentViewModelDelegate: class, ErrorPresenting, AlertActionsViewModelPersenting, ConfirmationPresenting {

    func refreshUI()
    func reloadPlaylistUI()
    func reloadUI()

    func reloadObjects(at indexPaths: [IndexPath])
}
