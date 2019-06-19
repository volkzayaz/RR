//
//  LibraryViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Parchment

class LibraryViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let x = R.storyboard.playerPlaylist.ownPlaylist()!
        x.title = "My playlists"
        x.viewModel = MyPlaylistsViewModel(router: MyPlaylistsRouter(owner: x))
        
        let y = R.storyboard.artist.artistsFollowedViewController()!
        y.title = "Following"
        y.viewModel = ArtistsFollowedViewModel(router: ArtistsFollowedRouter(owner: y))
        
        let pagingViewController = FixedPagingViewController(viewControllers: [x, y])
        pagingViewController.indicatorColor = .primaryPink
        pagingViewController.textColor = .white
        pagingViewController.selectedTextColor = .primaryPink
        pagingViewController.font = .systemFont(ofSize: 15, weight: .semibold)
        pagingViewController.selectedFont = .systemFont(ofSize: 15, weight: .semibold)
        pagingViewController.menuBackgroundColor = .primaryDark
        pagingViewController.borderOptions = .hidden
        pagingViewController.contentInteraction = .none
        pagingViewController.indicatorOptions = .visible(height: 1, zIndex: 1,
                                                         spacing: .zero, insets: .zero)
        
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
            ])
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
}
