//
//  ArtistRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct ArtistRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: ArtistRouter.T?
    init(owner: ArtistRouter.T) {
        self._owner = owner
    }
    
    func show(album: Album) {
    
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: AlbumPlaylistProvider(album: album,
                                                                         instantDownload: false))
        
        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func show(playlist: ArtistPlaylist) {
        
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: ArtistPlaylistProvider(artistPlaylist: playlist))
        
        owner.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showAddToPlaylist(for tracks: [Track]) {
        
        let x = R.storyboard.main.addToPlaylistViewController()!
        let r = AddToPlaylistRouter()
        r.start(controller: x, tracks: tracks)
        
        owner.present(UINavigationController(rootViewController: x), animated: true, completion: nil)
    }
    
    func trackListRouter() -> TrackListRouter {
        return TrackListRouter(owner: owner)
    }
    
}

