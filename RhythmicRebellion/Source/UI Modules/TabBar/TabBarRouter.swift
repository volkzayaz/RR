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
//    case listeningSettings
    //        case myMusic
    //        case search
    //        case mixer
}

protocol ForcedAuthorizationRouter: class {
    func routeToAuthorization(with authorizationType: AuthorizationType)
}

protocol TabBarRouter: FlowRouter, ForcedAuthorizationRouter {

    var playerContentContainerRouter: PlayerContentContainerRouter? { get set }

    func updateTabs(for types: [TabType])
    func selectTab(for type: TabType)

    func selectPage(with url: URL)
}

final class DefaultTabBarRouter: NSObject, TabBarRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case placeholder = "placeholder"
    }

    enum SegueActions: SegueDestinations {
        case placeholder

        var identifier: SegueDestinationList {
            switch self {
            case .placeholder: return SegueList.placeholder
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    weak var playerContentContainerRouter: PlayerContentContainerRouter?
    
    private(set) weak var viewModel: TabBarViewModel?
    private(set) weak var tabBarViewController: TabBarViewController?

    var sourceController: UIViewController? { return tabBarViewController }

    private(set) var childViewContollers: [UIViewController]?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultTabBarRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: TabBarViewController) {
        tabBarViewController = controller
        childViewContollers = controller.viewControllers
        tabBarViewController?.delegate = self
        let vm = TabBarControllerViewModel(router: self, application: self.dependencies.application)

        controller.configure(viewModel: vm, router: self, viewControllers: [])
    }

    func updateTabs(for types: [TabType]) {

        var viewControllers = [UIViewController]()

        for type in types {
            guard let viewController = self.viewController(for: type, from: self.childViewContollers) else { continue }

            switch type {
            case .home:
                guard let homeNavigationController = viewController as? UINavigationController,
                    let homeViewController = homeNavigationController.viewControllers.first as? HomeViewController else { break }

                homeNavigationController.popToRootViewController(animated: false)

                let homeRouter = DefaultHomeRouter(dependencies: self.dependencies)
                homeRouter.start(controller: homeViewController)
                viewControllers.append(homeNavigationController)

            case .settings:
                guard let settingsNavigationController = viewController as? UINavigationController,
                    let listeningSettingsViewController = settingsNavigationController.viewControllers.first as? ListeningSettingsViewController else { break }
                let listeningSettingsRouter = DefaultListeningSettingsRouter(dependencies: self.dependencies)
                listeningSettingsRouter.start(controller: listeningSettingsViewController)
                viewControllers.append(settingsNavigationController)

            case .pages:
                guard let pagesNavigationController = viewController as? UINavigationController,
                    let pagesViwController = pagesNavigationController.viewControllers.first as? PagesViewController else { break }

                pagesNavigationController.popToRootViewController(animated: false)

                let pagesRouter = DefaultPagesRouter(dependencies: self.dependencies, authorizationNavigationDelgate: self)
                pagesRouter.start(controller: pagesViwController)
                viewControllers.append(pagesNavigationController)

            case .profile:
                guard let profileNavigationController = viewController as? UINavigationController,
                    let profileViwController = profileNavigationController.viewControllers.first as? ProfileViewController else { break }
                let profileRouter = DefaultProfileRouter(dependencies: self.dependencies)
                profileRouter.start(controller: profileViwController)
                viewControllers.append(profileNavigationController)

            case .authorization:
                guard let authorizationNavigationController = viewController as? UINavigationController,
                    let authorizationViewController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController else { break }
                let authorizationRouter = DefaultAuthorizationRouter(dependencies: self.dependencies)
                authorizationRouter.start(controller: authorizationViewController)
                viewControllers.append(authorizationNavigationController)

//            case .listeningSettings:
//                guard let listeningSettingsViewController = viewController as? ListeningSettingsViewController else { break }
//                let listeningSettingsRouter = DefaultListeningSettingsRouter(dependencies: self.dependencies)
//                listeningSettingsRouter.start(controller: listeningSettingsViewController)
//                viewControllers.append(listeningSettingsViewController)


//            case .myMusic:
//            case .search:
//            case .mixer:
            default: break
            }
        }

        tabBarViewController?.viewControllers = viewControllers
    }

    func selectTab(for type: TabType) {
        guard let viewController = self.viewController(for: type, from: self.tabBarViewController?.viewControllers) else { return }
        self.tabBarViewController?.selectedViewController = viewController
    }

    private func viewController(for type: TabType, from viewControllers: [UIViewController]?) -> UIViewController? {
        return viewControllers?.filter( {
            guard let tabBarItem = $0.tabBarItem, let childViewControllerType = TabType(rawValue: tabBarItem.tag) else { return false}
            return childViewControllerType == type
        }).first
    }

    func selectPage(with url: URL) {
        guard let pagesNavigationController = self.viewController(for: .pages, from: self.tabBarViewController?.viewControllers) as? UINavigationController,
            let pagesViewController = pagesNavigationController.viewControllers.first as? PagesViewController else { return }

        pagesViewController.viewModel.navigateToPage(with: url)

        self.tabBarViewController?.selectedViewController = pagesNavigationController
        self.playerContentContainerRouter?.stop(true)
    }
}

extension DefaultTabBarRouter: ForcedAuthorizationRouter {

    func routeToAuthorization(with authorizationType: AuthorizationType) {

        guard let authorizationNavigationController = self.viewController(for: .authorization, from: self.tabBarViewController?.viewControllers) as? UINavigationController,
            let authorizationViwController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController
            else { return }

        self.tabBarViewController?.selectedViewController = authorizationNavigationController
        let authorizationRouter = DefaultAuthorizationRouter(dependencies: self.dependencies)
        authorizationRouter.start(controller: authorizationViwController)

        authorizationRouter.change(authorizationType: authorizationType)

        self.playerContentContainerRouter?.stop(true)
    }

}

extension DefaultTabBarRouter: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarItem = viewController.tabBarItem, let viewiewControllerType = TabType(rawValue: tabBarItem.tag) else { return }

        switch viewiewControllerType {
        case .authorization:
            guard let authorizationNavigationController = viewController as? UINavigationController,
                let authorizationViwController = authorizationNavigationController.viewControllers.first as? AuthorizationViewController else { break }
            let authorizationRouter = DefaultAuthorizationRouter(dependencies: self.dependencies)
            authorizationRouter.start(controller: authorizationViwController)

        case .settings:
            guard let settingsNavigationController = viewController as? UINavigationController,
                let listeningSettingsViewController = settingsNavigationController.viewControllers.first as? ListeningSettingsViewController else { break }
            let listeningSettingsRouter = DefaultListeningSettingsRouter(dependencies: self.dependencies)
            listeningSettingsRouter.start(controller: listeningSettingsViewController)

        case .profile:
            guard let profileNavigationController = viewController as? UINavigationController,
                let profileViewController = profileNavigationController.viewControllers.first as? ProfileViewController else { break }
            let profileRouter = DefaultProfileRouter(dependencies: self.dependencies)
            profileRouter.start(controller: profileViewController)


        default: break
        }

        self.playerContentContainerRouter?.stop(true)
    }
}
