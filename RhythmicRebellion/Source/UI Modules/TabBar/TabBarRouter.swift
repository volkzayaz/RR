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
    //        case myMusic
    //        case search
    //        case mixer
}

protocol TabBarRouter: FlowRouter {
    func updateTabs(for types: [TabType])
    func selectTab(for type: TabType)
}

final class DefaultTabBarRouter: NSObject, TabBarRouter, SegueCompatible {

    typealias Destinations = SegueList
    
    enum SegueList: String, SegueDestinations {
        case placeholder

        var identifier: String {
            switch self {
            case .placeholder: return "placeholder"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: TabBarViewModel?
    private(set) weak var tabBarViewController: TabBarViewController?

    var sourceController: UIViewController? { return tabBarViewController }

    private(set) var childViewContollers: [UIViewController]?


    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .placeholder:
            break
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
                guard let homeViewController = viewController as? HomeViewController else { break }
                let homeRouter = DefaultHomeRouter(dependencies: self.dependencies)
                homeRouter.start(controller: homeViewController)
                viewControllers.append(homeViewController)

            case .settings:
                guard let settingsViwController = viewController as? SettingsViewController else { break }
                let settingsRouter = DefaultSettingsRouter(dependencies: self.dependencies)
                settingsRouter.start(controller: settingsViwController)
                viewControllers.append(settingsViwController)

            case .pages:
                guard let pagesViwController = viewController as? PagesViewController else { break }
                let pagesRouter = DefaultPagesRouter(dependencies: self.dependencies)
                pagesRouter.start(controller: pagesViwController)
                viewControllers.append(pagesViwController)

            case .profile:
                guard let profileViwController = viewController as? ProfileViewController else { break }
                let profileRouter = DefaultProfileRouter(dependencies: self.dependencies)
                profileRouter.start(controller: profileViwController)
                viewControllers.append(profileViwController)

            case .authorization:
                guard let authorizationViwController = viewController as? AuthorizationViewController else { break }
                let authorizationRouter = DefaultAuthorizationRouter(dependencies: self.dependencies)
                authorizationRouter.start(controller: authorizationViwController)
                viewControllers.append(authorizationViwController)

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
}

extension DefaultTabBarRouter: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let tabBarItem = viewController.tabBarItem, let viewiewControllerType = TabType(rawValue: tabBarItem.tag) else { return }

        switch viewiewControllerType {
        case .authorization:
            guard let authorizationViwController = viewController as? AuthorizationViewController else { return }
            let authorizationRouter = DefaultAuthorizationRouter(dependencies: self.dependencies)
            authorizationRouter.start(controller: authorizationViwController)
        default: break
        }
    }

}
