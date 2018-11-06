//
//  AddPlaylistToPlaylistControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

final class AddPlaylistToPlaylistControllerViewModel: AddToPlaylistControllerViewModel {

    let attachingPlaylist: Playlist

    init(router: AddToPlaylistRouter, application: Application, restApiService: RestApiService, playlist: Playlist) {

        self.attachingPlaylist = playlist
        var excludedPlaylists: [FanPlaylist] = [FanPlaylist]()

        if let attachingFanPlaylist = playlist as? FanPlaylist {
            excludedPlaylists.append(attachingFanPlaylist)
        }

        super.init(router: router, application: application, restApiService: restApiService, excludedPlaylists: excludedPlaylists)
    }

    override func select(playlist: FanPlaylist) {

        switch attachingPlaylist {
        case let attachingDefinedPlaylist as DefinedPlaylist: self.attach(attachingDefinedPlaylist, to: playlist)
        case let attachingFanPlaylist as FanPlaylist: self.attach(attachingFanPlaylist, to: playlist)
        default: break
        }
    }

    func attach(_ attachingPlaylist: DefinedPlaylist, to playlist: FanPlaylist) {
        self.delegate?.showProgress()
        self.restApiService.fanAttach(playlist: attachingPlaylist, to: playlist) { [weak self] (error) in
            self?.delegate?.hideProgress()
            guard let error = error else { self?.router?.dismiss(); return }
            self?.delegate?.show(error: error)
        }
    }

    func attach(_ attachingPlaylist: FanPlaylist, to playlist: FanPlaylist) {
        self.delegate?.showProgress()
        self.restApiService.fanAttach(playlist: attachingPlaylist, to: playlist) { [weak self] (attachPlaylistResult) in
            self?.delegate?.hideProgress()
            switch attachPlaylistResult {
            case .success(_): self?.router?.dismiss()
            case .failure(let error): self?.delegate?.show(error: error)
            }
        }
    }
}
