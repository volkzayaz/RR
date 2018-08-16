//
//  PlaylistsCollectionControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class FanPlaylistsCollectionControllerViewModel: PlaylistsCollectionViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistsCollectionViewModelDelegate?
    private(set) weak var router: PlaylistsCollectionRouter?
    private(set) weak var restApiService: RestApiService?

    private(set) var playlists: [PlaylistShort] = [PlaylistShort]()

    // MARK: - Lifecycle -

    init(router: PlaylistsCollectionRouter, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService
    }

    func load(with delegate: PlaylistsCollectionViewModelDelegate) {
        self.delegate = delegate

        self.loadPlaylists()

        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadPlaylists()
    }

    func loadPlaylists() {
        self.restApiService?.fanPlaylists(completion: { [weak self] (playlistsResult) in

            switch playlistsResult {
            case .success(let playlists):
                self?.playlists = playlists
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error)
            }
        })
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlists.count
    }

    func object(at indexPath: IndexPath) -> PlaylistItemCollectionViewCellViewModel? {
        guard indexPath.item < self.playlists.count else { return nil }

        return ShortPlaylistItemViewModel(playlist: self.playlists[indexPath.item])
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }
}