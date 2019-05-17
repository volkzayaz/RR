//
//  MyPlaylistsRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

struct MyPlaylistsRouter {
    
    weak var owner: UIViewController?
    
    init(owner: UIViewController) {
        self.owner = owner
    }
    
    func showContent(of playlist: FanPlaylist) {
        
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: FanPlaylistProvider(fanPlaylist: playlist))
        
        owner?.navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
