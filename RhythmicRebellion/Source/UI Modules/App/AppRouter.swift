//
//  AppRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AppRouter: FlowRouter {
}

final class DefaultAppRouter:  AppRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case player
        case tabBar

        var identifier: String {
            switch self {
            case .player: return "PlayerSegueIdentifier"
            case .tabBar: return "TabBarSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "PlayerSegueIdentifier": return .player
            case "TabBarSegueIdentifier": return .tabBar
            default: return nil
            }
        }
    }

    var dependencies: RouterDependencies

    private(set) weak var viewModel: AppViewModel?
    private(set) weak var sourceController: UIViewController?

    private(set) weak var tabBarViewController: TabBarViewController?
    private(set) weak var tabBarRouter: TabBarRouter?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .player:
            guard let playerViewController = segue.destination as? PlayerViewController else { fatalError("Incorrect controller for PlayerSegueIdentifier") }
            let playerRouter = DefaultPlayerRouter(dependencies: self.dependencies)
            playerRouter.start(controller: playerViewController, navigationDelegate: self)

        case .tabBar:
            guard let tabBarViewController = segue.destination as? TabBarViewController else { fatalError("Incorrect controller for TabBarViewController") }
            let tabBarRouter = DefaultTabBarRouter(dependencies: self.dependencies, playerContentTransitioningDelegate: PlayerContentTransitioningDelegate())
            tabBarRouter.start(controller: tabBarViewController)
            self.tabBarRouter = tabBarRouter
            self.tabBarViewController = tabBarViewController
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AppViewController) {
        sourceController = controller
        let vm = AppControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
}

extension DefaultAppRouter: PlayerNavigationDelgate {

    func navigate(to playerNavigationItem: PlayerNavigationItem) {

        guard let playerContentContainerRouter = self.tabBarRouter?.playerContentContainerRouter else {
            self.tabBarViewController?.performSegue(withIdentifier: "PlayerContantContainerSegueIdentifier", sender: playerNavigationItem)
            return
        }

        playerContentContainerRouter.navigate(to: playerNavigationItem)
    }

}

