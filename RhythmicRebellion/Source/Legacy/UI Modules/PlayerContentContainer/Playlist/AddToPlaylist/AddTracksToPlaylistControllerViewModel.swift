//
//  AddTracksToPlaylistControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/6/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

final class AddTracksToPlaylistControllerViewModel: AddToPlaylistControllerViewModel {

    private let tracks : [Track]

    init(router: AddToPlaylistRouter, tracks : [Track]) {
        self.tracks = tracks
        super.init(router: router, excludedPlaylists: [])
    }

    override func select(playlist: FanPlaylist) {
        //self.delegate?.showProgress()
        
        PlaylistRequest.attachTracks(tracks, to: playlist)
            .rx.emptyResponse()
            .catchError({ (error) -> Maybe<Void> in
                
                if let e = error as? AFError, e.responseCode == 422 {
                    throw RRError.generic(message: "This track has been already added to this playlist")
                }
                
                throw error
            })
            .silentCatch(handler: router?.sourceController)
            .subscribe(onNext: {
                self.router?.dismiss()
            })
    }
}
