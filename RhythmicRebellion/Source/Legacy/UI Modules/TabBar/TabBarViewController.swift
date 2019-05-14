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

        viewModel.tabs
            .drive(onNext: { [unowned self] (x) in
                
                var viewControllers = [UIViewController]()
                
                for type in x {
                    guard let viewController = self.viewController(for: type,
                                                                   from: self.viewControllers) else { continue }
                    
                    switch type {
                    case .home:
                        guard let homeNavigationController = viewController as? UINavigationController,
                            let homeViewController = homeNavigationController.viewControllers.first as? HomeViewController else { break }
                        
                        homeNavigationController.popToRootViewController(animated: false)
                        
                        let homeRouter = HomeRouter()
                        homeRouter.start(controller: homeViewController)
                        viewControllers.append(homeNavigationController)
                        
                    case .settings:
                        guard let settingsNavigationController = viewController as? UINavigationController,
                            let listeningSettingsViewController = settingsNavigationController.viewControllers.first as? ListeningSettingsViewController else { break }
                        let listeningSettingsRouter = DefaultListeningSettingsRouter()
                        listeningSettingsRouter.start(controller: listeningSettingsViewController)
                        viewControllers.append(settingsNavigationController)
                        
                    case .pages:
                        guard let pagesNavigationController = viewController as? UINavigationController,
                            let pagesViwController = pagesNavigationController.viewControllers.first as? PagesViewController else { break }
                        
                        pagesNavigationController.popToRootViewController(animated: false)
                        
                        let pagesRouter = DefaultPagesRouter(authorizationNavigationDelgate: self.viewModel.router)
                        pagesRouter.start(controller: pagesViwController)
                        viewControllers.append(pagesNavigationController)
                        
                    case .profile:
                        guard let profileNavigationController = viewController as? UINavigationController,
                            let profileViwController = profileNavigationController.viewControllers.first as? ProfileViewController else { break }
                        let profileRouter = DefaultProfileRouter()
                        profileRouter.start(controller: profileViwController)
                        viewControllers.append(profileNavigationController)
                        
                    case .authorization:
                        guard let authorizationNavigationController = viewController as? UINavigationController,
                            let authorizationViewController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController else { break }
                        let authorizationRouter = DefaultAuthorizationRouter()
                        authorizationRouter.start(controller: authorizationViewController)
                        viewControllers.append(authorizationNavigationController)
                        
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
