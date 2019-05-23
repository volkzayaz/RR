//
//  RootRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct RootRouter : MVVM_Router {
    
    var owner: UIViewController {
        return _owner!
    }
    
    weak private var _owner: RootRouter.T?
    init(owner: RootRouter.T) {
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
