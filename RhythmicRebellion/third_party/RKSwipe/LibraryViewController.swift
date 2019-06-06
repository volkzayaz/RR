//
//  LibraryViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class LibraryViewController: RKSwipeBetweenViewControllers {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let x = R.storyboard.main.vc1()
        
        
        let y = R.storyboard.artist.artistsFollowedViewController()!
        y.viewModel = ArtistsFollowedViewModel(router: ArtistsFollowedRouter(owner: y))
        
        viewControllerArray.addObjects(from: [x, y])
        
        buttonText = ["My playlists", "Following"]
        
    }
    
    
    
}
