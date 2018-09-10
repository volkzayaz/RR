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

final class DefaultAppRouter:  AppRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case player = "PlayerSegueIdentifier"
        case tabBar = "TabBarSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case player
        case tabBar

        var identifier: SegueDestinationList {
            switch self {
            case .player: return SegueList.player
            case .tabBar: return SegueList.tabBar
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .player?: self = .player
            case .tabBar?: self = .tabBar
            default: fatalError("UPS!")
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

    func prepare(for destination: DefaultAppRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
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
            self.tabBarRouter?.showPlayerContentContainer(playerNavigationItem: playerNavigationItem)
            return
        }

        playerContentContainerRouter.navigate(to: playerNavigationItem)
    }

}

