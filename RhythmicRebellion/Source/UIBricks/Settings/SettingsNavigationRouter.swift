//
//  SettingsNavigationRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/5/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct SettingsNavigationRouter : MVVM_Router {
    
    var owner: UINavigationController {
        return _owner!
    }
    
    weak private var _owner: SettingsNavigationRouter.T?
    init(owner: SettingsNavigationRouter.T) {
        self._owner = owner
    }
    
    func switchToProfile() {
        let x = R.storyboard.profile.profileViewController()!
        let router = DefaultProfileRouter()
        router.start(controller: x)
        
        owner.setViewControllers([x], animated: true)
    }
    
    func switchToAuth() {
        let x = R.storyboard.authorization.authorizationViewController()!
        let router = DefaultAuthorizationRouter()
        router.start(controller: x)
        
        owner.setViewControllers([x], animated: true)
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
