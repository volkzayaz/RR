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
    var dependencies: RouterDependencies { get }
}

final class DefaultAppRouter:  AppRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case player = "PlayerSegueIdentifier"
        case contentContainer = "ContentContainerSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case player
        case contentContainer

        var identifier: SegueDestinationList {
            switch self {
            case .player: return SegueList.player
            case .contentContainer: return SegueList.contentContainer
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .player?: self = .player
            case .contentContainer?: self = .contentContainer
            default: fatalError("Unknown destination!")
            }
        }
    }

    var dependencies: RouterDependencies

    private(set) weak var viewModel: AppViewModel?
    private(set) weak var appViewController: AppViewController?

    var sourceController: UIViewController? { return appViewController }

    private(set) weak var contentContainerViewController: ApplicationContentContainerViewController?
    private(set) weak var contentContainerRouter: ApplicationContentContainerRouter?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultAppRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .player:
            guard let playerViewController = segue.destination as? PlayerViewController else { fatalError("Incorrect controller for PlayerSegueIdentifier") }
            let playerRouter = DefaultPlayerRouter(dependencies: self.dependencies, navigationDelegate: self)
            playerRouter.start(controller: playerViewController)

        case .contentContainer:
            guard let contentContainerViewController = segue.destination as? ApplicationContentContainerViewController else { fatalError("Incorrect controller for ContentContainerSegueIdentifier") }
            let contentContainerRouter = DefaultApplicationContentContainerRouter(dependencies: self.dependencies)
            contentContainerRouter.start(controller: contentContainerViewController)
            self.appViewController?.contentContainerViewController = contentContainerViewController
            self.contentContainerRouter = contentContainerRouter
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AppViewController) {
        appViewController = controller
        let vm = AppControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
}

extension DefaultAppRouter: PlayerNavigationDelgate {

    func navigate(to playerNavigationItem: PlayerNavigationItem) {
        self.contentContainerRouter?.navigate(to: playerNavigationItem)
    }

    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.contentContainerRouter?.routeToAuthorization(with: authorizationType)
    }
}

