//
//  HomeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class HomeControllerViewModel: HomeViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: HomeViewModelDelegate?
    private(set) weak var router: HomeRouter?
    private(set) weak var restApiService: RestApiService?

    private(set) var playlists: [Playlist] = [Playlist]()

    // MARK: - Lifecycle -

    init(router: HomeRouter, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService
    }

    func load(with delegate: HomeViewModelDelegate) {
        self.delegate = delegate

        self.loadPlaylists()

        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadPlaylists()
    }

    func loadPlaylists() {

        self.restApiService?.playlists(completion: { [weak self] (playlistsResult) in

            switch playlistsResult {
            case .success(let playlists):
                self?.playlists = playlists
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            }
        })
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlists.count
    }

    func object(at indexPath: IndexPath) -> PlaylistItemViewModel? {
        guard indexPath.item < self.playlists.count else { return nil }

        return PlaylistItemViewModel(playlist: self.playlists[indexPath.item])
    }

    func selectObject(at indexPath: IndexPath) {
        self.router?.showContent(of: self.playlists[indexPath.item])
    }

}
