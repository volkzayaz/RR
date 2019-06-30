//
//  RootTabBarController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import RxSwift

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
            .skip(1)
            .filter { !$0 }
            .drive(onNext: { [unowned self] (isGuest) in
                
                guard self.viewControllers!.count == 3 else {
                    fatalErrorInDebug("Please update login logic for RootTabBarController")
                    return
                }
                
                var x = self.viewControllers!
                
                let y = R.storyboard.main.libraryNavigationController()!
                x.insert(y, at: 2)
                
                self.setViewControllers(x, animated: true)
                return
                
            })
            .disposed(by: rx.disposeBag)
     
        NotificationCenter.default.rx.notification(NSNotification.Name(rawValue: "navigateToPage"))
            .subscribe(onNext: { [unowned self] (n) in
                guard let url = n.userInfo?["url"] as? URL else { return }
                
                self.selectedIndex = 1
                self.dismiss(animated: true, completion: {
                    let x = (self.viewControllers![1] as! UINavigationController).viewControllers.first! as! PagesViewController
                    x.viewModel.navigateToPage(with: url)
                })
                
            })
            .disposed(by: rx.disposeBag)

        ////TODO: kill it with fire =)
        NotificationCenter.default.rx.notification(NSNotification.Name(rawValue: "navigateToSignIn"))
            .subscribe(onNext: { [unowned self] (n) in
                
                self.selectedIndex = 2
//                self.dismiss(animated: true, completion: {
//                    let x = (self.viewControllers![1] as! UINavigationController).viewControllers.first! as! PagesViewController
//                    x.viewModel.navigateToPage(with: url)
//                })
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}
