//
//  PlayerMyPlaylistsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerMyPlaylistsControllerViewModel: PlayerMyPlaylistsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerMyPlaylistsViewModelDelegate?
    private(set) weak var router: PlayerMyPlaylistsRouter?
    private let restApiService: RestApiService
    private let application: Application

    private(set) var playlists: [FanPlaylist] = [FanPlaylist]()


    // MARK: - Lifecycle -

    init(router: PlayerMyPlaylistsRouter, restApiService: RestApiService, application: Application) {
        self.router = router
        self.restApiService = restApiService
        self.application = application
    }

    func load(with delegate: PlayerMyPlaylistsViewModelDelegate) {
        self.delegate = delegate

        if (!(self.application.user?.isGuest ?? true)) {
            self.loadPlaylists()
            self.delegate?.reloadUI()
        }
    }

    func reload() {
        if (!(self.application.user?.isGuest ?? true)) {
            self.loadPlaylists()
        }
    }

    func loadPlaylists() {
        self.restApiService.fanPlaylists(completion: { [weak self] (playlistsResult) in

            switch playlistsResult {
            case .success(let playlists):
                self?.playlists = playlists
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in  self?.delegate?.reloadUI() })
            }
        })
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlists.count
    }

    func object(at indexPath: IndexPath) -> PlaylistItemCollectionViewCellViewModel? {
        guard indexPath.item < self.playlists.count else { return nil }

        return PlaylistItemViewModel(playlist: self.playlists[indexPath.item])
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }
}
