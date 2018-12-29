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
                                   audioFileLocalStorageService: DataLayer.get.audioFileLocalStorageService,
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
                                   audioFileLocalStorageService: DataLayer.get.audioFileLocalStorageService,
                                   provider: ArtistPlaylistProvider(artistPlaylist: playlist))
        vc.configure(viewModel: vm, router: router)
        
        owner.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func present(actions: AlertActionsViewModel<ActionViewModel>, sourceRect: CGRect, sourceView: UIView) {
        
        owner.show(alertActionsviewModel: actions,
                   sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
    func openIn(for url: URL, sourceRect: CGRect, sourceView: UIView) {
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sourceView
        activityViewController.popoverPresentationController?.sourceRect = sourceRect
        
        owner.present(activityViewController, animated: true, completion: nil)
        
    }
    
    func showTip(text: String, view: UIView, superView: UIView) {
        
        let tipView = TipView(text: text, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: view, in: superView)
        
    }
    
    
    //                case .openIn(let sourceRect, let sourceView): self.showOpenIn(itemAt: indexPath,
    //                                                                              sourceRect: sourceRect,
    //                                                                              sourceView: sourceView)
    //                case .showHint(let sourceView, let hintText): self.showHint(sourceView: sourceView, text: hintText)

    
    /**
     
     func showNextModule(with data: String) {
     
        let nextViewController = owner.storyboard.instantiate()
        let nextRouter = NextRouter(owner: nextViewController)
        let nextViewModel = NextViewModel(router: nextRuter, data: data)
        
        nextViewController.viewModel = nextViewModel
        owner.present(nextViewController)
     }
     
     */
    
}

