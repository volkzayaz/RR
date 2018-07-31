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

    // MARK: - Lifecycle -

    init(router: HomeRouter, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService
    }

    func load(with delegate: HomeViewModelDelegate) {
        self.delegate = delegate

//        self.restApiService?.playlists(completion: { [weak self] (playlistsResult) in
//
//            switch playlistsResult {
//            case .success(let playlists):
//                print("playlists: \(playlists)")
//                guard playlists.count > 0 else { return }
//                self?.loadTracks(for: playlists.first!.id)
//
//            case .failure(let error):
//                print("playlists: \(error)")
//            }
//        })
    }

//    func loadTracks(for playlistId: Int) {
//
//        self.restApiService?.tracks(for: playlistId, completion: { (playlistTracksResult) in
//            switch playlistTracksResult {
//            case .success(let playlistTracks):
//                print("playlistTracks: \(playlistTracks)")
//            case .failure(let error):
//                print("playlistTracks: \(error)")
//            }
//        })
//    }
}
