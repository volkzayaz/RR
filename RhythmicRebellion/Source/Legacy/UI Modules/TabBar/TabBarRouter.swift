//
//  TabBarRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum TabType: Int {
    case unknown
    case home
    case settings
    case pages
    case profile
    case authorization
}

protocol ForcedAuthorizationRouter: class {
    func routeToAuthorization(with authorizationType: AuthorizationType)
}

final class TabBarRouter: NSObject {

    weak var playerContentContainerRouter: PlayerContentContainerRouter?
    
    weak var tabBarViewController: TabBarViewController?
    init(owner: TabBarViewController) {
        self.tabBarViewController = owner
    }

}

extension TabBarRouter: ForcedAuthorizationRouter {

    func routeToAuthorization(with authorizationType: AuthorizationType) {

        guard let authorizationNavigationController = self.tabBarViewController?.viewController(for: .authorization, from: self.tabBarViewController?.viewControllers) as? UINavigationController,
            let authorizationViwController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController
            else { return }

        self.tabBarViewController?.selectedViewController = authorizationNavigationController
        let authorizationRouter = DefaultAuthorizationRouter()
        authorizationRouter.start(controller: authorizationViwController)

        authorizationRouter.change(authorizationType: authorizationType)

        self.playerContentContainerRouter?.stop(true)
    }

}

extension TabBarRouter: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarItem = viewController.tabBarItem, let viewiewControllerType = TabType(rawValue: tabBarItem.tag) else { return }

        switch viewiewControllerType {
        case .authorization:
            guard let authorizationNavigationController = viewController as? UINavigationController,
                let authorizationViwController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController else { break }
            let authorizationRouter = DefaultAuthorizationRouter()
            authorizationRouter.start(controller: authorizationViwController)

        case .settings:
            guard let settingsNavigationController = viewController as? UINavigationController,
                let listeningSettingsViewController = settingsNavigationController.viewControllers.first as? ListeningSettingsViewController else { break }
            let listeningSettingsRouter = DefaultListeningSettingsRouter()
            listeningSettingsRouter.start(controller: listeningSettingsViewController)

        case .profile:
            guard let profileNavigationController = viewController as? UINavigationController,
                let profileViewController = profileNavigationController.viewControllers.first as? ProfileViewController else { break }
            let profileRouter = DefaultProfileRouter()
            profileRouter.start(controller: profileViewController)


        default: break
        }

        self.playerContentContainerRouter?.stop(true)
    }
}
