//
//  ArtistRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/28/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct ArtistRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: ArtistRouter.T?
    init(owner: ArtistRouter.T) {
        self._owner = owner
    }
    
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

