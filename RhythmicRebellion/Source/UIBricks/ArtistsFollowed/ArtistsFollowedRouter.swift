//
//  ArtistsFollowedRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct ArtistsFollowedRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: ArtistsFollowedRouter.T?
    init(owner: ArtistsFollowedRouter.T) {
        self._owner = owner
    }
    
    func presentArtist(artist: Artist) {
        
        let vc = R.storyboard.artist.instantiateInitialViewController()!
        vc.viewModel = ArtistViewModel(router: ArtistRouter(owner: vc), artist: artist)
        owner.present(vc.embededIntoNavigation(), animated: true, completion: nil)
        
    }
    
}
