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
        
        let router = DefaultPlaylistContentRouter(dependencies: DataLayer.get)
        
        let vm = PlaylistViewModel(router: router,
                                   application: DataLayer.get.application,
                                   player: DataLayer.get.player,
                                   restApiService: DataLayer.get.restApiService,
                                   provider: AlbumPlaylistProvider(album: album))
        vc.configure(viewModel: vm, router: router)

        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func show(playlist: ArtistPlaylist) {
        
        let vc = R.storyboard.main.playlistContentViewController()!
        
        let router = DefaultPlaylistContentRouter(dependencies: DataLayer.get)
        
        let vm = PlaylistViewModel(router: router,
                                   application: DataLayer.get.application,
                                   player: DataLayer.get.player,
                                   restApiService: DataLayer.get.restApiService,
                                   provider: ArtistPlaylistProvider(artistPlaylist: playlist))
        vc.configure(viewModel: vm, router: router)
        
        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func present(actions: AlertActionsViewModel<ActionViewModel>, sourceRect: CGRect, sourceView: UIView) {
        
        owner.show(alertActionsviewModel: actions,
                   sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
    func showTip(text: String, view: UIView, superView: UIView) {
        
        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: view, in: superView)
        
    }
    
    func trackListRouter() -> TrackListRouter {
        return TrackListRouter(owner: owner)
    }
    
}

