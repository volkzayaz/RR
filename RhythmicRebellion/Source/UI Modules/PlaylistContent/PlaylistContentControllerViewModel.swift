//
//  PlaylistContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlaylistContentControllerViewModel: PlaylistContentViewModel {


    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistContentViewModelDelegate?
    private(set) weak var router: PlaylistContentRouter?
    private(set) weak var restApiService: RestApiService?

    private var playlist: Playlist
    private var playlistTracks: [Track] = [Track]()    

    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist) }

    // MARK: - Lifecycle -

    init(router: PlaylistContentRouter, restApiService: RestApiService, playlist: Playlist) {
        self.router = router
        self.restApiService = restApiService

        self.playlist = playlist
    }

    func load(with delegate: PlaylistContentViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()
        self.delegate?.reloadUI()
    }

    func loadTracks() {
        self.restApiService?.tracks(for: self.playlist.id, completion: { [weak self] (tracksResult) in

            switch tracksResult {
            case .success(let tracks):
                self?.playlistTracks = tracks
                self?.delegate?.reloadUI()
            case .failure(let error):
                self?.delegate?.show(error: error)
            }
        })
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistTracks.count
    }

    func object(at indexPath: IndexPath) -> TrackItemViewModel? {
        guard indexPath.item < self.playlistTracks.count else { return nil }

        return TrackItemViewModel(track: self.playlistTracks[indexPath.item])
    }
}
