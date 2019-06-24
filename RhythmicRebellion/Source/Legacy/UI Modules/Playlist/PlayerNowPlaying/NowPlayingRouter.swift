//
//  NowPlayingRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
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
        
        let r = R.storyboard.main.addToPlaylistContainer()!
        let x = R.storyboard.main.addToPlaylistViewController()!
        
        x.viewModel = .init(router: .init(owner: x), attachable: tracks)
        
        r.viewControllers = [x]
        
        owner.present(r, animated: true, completion: nil)
        
    }
}
