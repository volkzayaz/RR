//
//  AddTracksToPlaylistControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

final class AddTracksToPlaylistControllerViewModel: AddToPlaylistControllerViewModel {

    private let tracks : [Track]

    init(router: AddToPlaylistRouter, application: Application, restApiService: RestApiService, tracks : [Track]) {
        self.tracks = tracks
        super.init(router: router, application: application, restApiService: restApiService, excludedPlaylists: [])
    }

    override func select(playlist: FanPlaylist) {
        self.delegate?.showProgress()
        restApiService.fanAttach(self.tracks, to: playlist) {[weak self] (result) in
            self?.delegate?.hideProgress()
            switch result {
            case .success(_):
                self?.router?.dismiss()
            case .failure(let error):
                self?.delegate?.show(error: error)
            }
        }
    }
}
