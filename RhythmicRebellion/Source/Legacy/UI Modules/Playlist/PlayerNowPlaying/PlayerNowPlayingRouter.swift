//
//  PlayerNowPlayingRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct NowPlayingRouter: MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: NowPlayingRouter.T?
    init(owner: NowPlayingRouter.T) {
        self._owner = owner
    }
    
    func showAddToPlaylist(for tracks: [Track]) {
        
        let x = R.storyboard.main.addToPlaylistViewController()!
        let r = AddToPlaylistRouter()
        r.start(controller: x, tracks: tracks)
        
        owner.present(UINavigationController(rootViewController: x), animated: true, completion: nil)
        
    }
}
