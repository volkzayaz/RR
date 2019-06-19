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

    init(router: AddToPlaylistRouter, playlist: Playlist) {

        self.attachingPlaylist = playlist
        var excludedPlaylists: [FanPlaylist] = [FanPlaylist]()

        if let attachingFanPlaylist = playlist as? FanPlaylist {
            excludedPlaylists.append(attachingFanPlaylist)
        }

        super.init(router: router, excludedPlaylists: excludedPlaylists)
    }

    override func select(playlist: FanPlaylist) {

        switch attachingPlaylist {
        case let attachingDefinedPlaylist as DefinedPlaylist: self.attach(attachingDefinedPlaylist, to: playlist)
        case let attachingFanPlaylist as FanPlaylist: self.attach(attachingFanPlaylist, to: playlist)
        default: break
        }
    }

    func attach(_ attachingPlaylist: DefinedPlaylist, to playlist: FanPlaylist) {
        
        PlaylistRequest.attachRR(playlist: attachingPlaylist, to: playlist)
            .rx.emptyResponse()
            .subscribe(onSuccess: {
                self.router?.dismiss()
            })
        
    }

    func attach(_ attachingPlaylist: FanPlaylist, to playlist: FanPlaylist) {
        
        PlaylistRequest.attach(playlist: attachingPlaylist, to: playlist)
            .rx.emptyResponse()
            .subscribe(onSuccess: {
                self.router?.dismiss()
            })

    }
}
