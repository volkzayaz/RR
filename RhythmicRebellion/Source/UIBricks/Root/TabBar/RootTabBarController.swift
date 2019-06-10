//
//  RootTabBarController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class RootTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appState.map { $0.user.isGuest }
            .distinctUntilChanged()
            .filter { $0 }
            .drive(onNext: { [unowned self] (isGuest) in
                
                guard self.viewControllers!.count == 4 else {
                    fatalErrorInDebug("Please update logout logic for RootTabBarController")
                    return
                }
                
                var x = self.viewControllers!
                x.remove(at: 2)
                self.setViewControllers(x, animated: true)
                
            })
            .disposed(by: rx.disposeBag)
        
        appState.map { $0.user.isGuest }
            .distinctUntilChanged()
            .filter { !$0 }
            .skip(1)
            .drive(onNext: { [unowned self] (isGuest) in
                
                guard self.viewControllers!.count == 3 else {
                    fatalErrorInDebug("Please update login logic for RootTabBarController")
                    return
                }
                
                var x = self.viewControllers!
                
                let y = R.storyboard.main.libraryViewController()!
                x.insert(y, at: 2)
                
                self.setViewControllers(x, animated: true)
                return
                
            })
            .disposed(by: rx.disposeBag)
        

        
    }
    
}
