//
//  TabBarViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class TabBarViewController: UITabBarController {

    var viewModel: TabBarViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        //tabBar.delegate = self
        
        viewModel.tabs
            .drive(onNext: { [unowned self] (x) in
                
                var viewControllers = [UIViewController]()
                
                for type in x {
                    let viewController = self.viewController(for: type,
                                                             from: self.viewControllers)
                    
                    switch type {
                    case .home:
                        guard let homeNavigationController = viewController as? UINavigationController,
                            let homeViewController = homeNavigationController.viewControllers.first as? HomeViewController else { break }
                        
                        homeNavigationController.popToRootViewController(animated: false)
                        
                        homeViewController.viewModel = HomeViewModel(router: .init(owner: homeViewController))
                        
                        viewControllers.append(homeNavigationController)
                        
                    case .settings:
                        
                        let x = R.storyboard.main.settingsViewController()!
                        
                        let listeningSettingsRouter = DefaultListeningSettingsRouter()
                        listeningSettingsRouter.start(controller: x.viewControllers.first! as! ListeningSettingsViewController)
                        
                        viewControllers.append(x)
                        
                    case .pages:
                        guard let pagesNavigationController = viewController as? UINavigationController,
                            let pagesViwController = pagesNavigationController.viewControllers.first as? PagesViewController else { break }
                        
                        pagesNavigationController.popToRootViewController(animated: false)
                        
                        let pagesRouter = DefaultPagesRouter(authorizationNavigationDelgate: self.viewModel.router)
                        pagesRouter.start(controller: pagesViwController)
                        viewControllers.append(pagesNavigationController)
                        
                    case .profile:
                        
                        let x = R.storyboard.profile.profileNavigationController()!
                        
                        let profileRouter = DefaultProfileRouter()
                        profileRouter.start(controller: x.viewControllers.first! as! ProfileViewController)
                        viewControllers.append(x)
                        
                    case .authorization:
                        
                        let x = R.storyboard.authorization.authorizationViewController()!
                        
                        let authorizationRouter = DefaultAuthorizationRouter()
                        authorizationRouter.start(controller: x.viewControllers.first! as! AuthorizationViewController)
                        
                        viewControllers.append(x)
                        
                    default: break
                    }
                }
                
                self.viewControllers = viewControllers
            })
            .disposed(by: rx.disposeBag)

        viewModel.openedTab
            .drive(onNext: { [unowned self] (x) in
                self.selectTab(for: x)
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    func viewController(for type: TabType, from viewControllers: [UIViewController]?) -> UIViewController? {
        return viewControllers?.filter( {
            guard let tabBarItem = $0.tabBarItem, let childViewControllerType = TabType(rawValue: tabBarItem.tag) else { return false}
            return childViewControllerType == type
        }).first
    }
    
    func selectTab(for type: TabType) {
        guard let viewController = self.viewController(for: type, from: self.viewControllers) else { return }
        self.selectedViewController = viewController
    }
    
    func selectPage(with url: URL) {
        guard let pagesNavigationController = self.viewController(for: .pages, from: self.viewControllers) as? UINavigationController,
            let pagesViewController = pagesNavigationController.viewControllers.first as? PagesViewController else { return }
        
        pagesViewController.viewModel.navigateToPage(with: url)
        
        self.selectedViewController = pagesNavigationController
        self.viewModel.router.playerContentContainerRouter?.stop(true)
    }
    
}

extension TabBarViewController {
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        //super.tabBar(tabBar, didSelect: item)
        
        self.viewModel.router.playerContentContainerRouter?.stop(true)
    }
    
}
