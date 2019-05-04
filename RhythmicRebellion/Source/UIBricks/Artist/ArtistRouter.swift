//
//  ArtistRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import EasyTipView

struct ArtistRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: ArtistRouter.T?
    init(owner: ArtistRouter.T) {
        self._owner = owner
    }
    
    func show(album: Album) {
    
        let vc = R.storyboard.main.playlistContentViewController()!
        
        let router = PlaylistRouter(dependencies: DataLayer.get)
        router.sourceController = vc
        
        let vm = PlaylistViewModel(router: router,
                                   provider: AlbumPlaylistProvider(album: album,
                                                                   instantDownload: false))
        vc.configure(viewModel: vm, router: router)

        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func show(playlist: ArtistPlaylist) {
        
        let vc = R.storyboard.main.playlistContentViewController()!
        
        let router = PlaylistRouter(dependencies: DataLayer.get)
        
        let vm = PlaylistViewModel(router: router,
                                   provider: ArtistPlaylistProvider(artistPlaylist: playlist))
        vc.configure(viewModel: vm, router: router)
        
        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func trackListRouter() -> TrackListRouter {
        return TrackListRouter(owner: owner)
    }
    
}

