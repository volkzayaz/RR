//
//  HomeRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct HomeRouter {

    weak var owner: UIViewController?

    init(owner: UIViewController) {
        self.owner = owner
    }

    func showContent(of playlist: DefinedPlaylist) {
        
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: DefinedPlaylistProvider(playlist: playlist))
        
        owner?.navigationController?.pushViewController(vc, animated: true)
        
    }

}
