//
//  PlayerContentContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerContentContainerRouter: FlowRouter {
    func navigate(to playerNavigationItem: PlayerNavigationItem)
    func stop(_ animated: Bool)
}

final class DefaultPlayerContentContainerRouter:  PlayerContentContainerRouter, FlowRouterSegueCompatible {

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

    var dependencies: RouterDependencies

    private(set) weak var viewModel: PlayerContentContainerViewModel?
    private(set) weak var playerContentContainerViewController: PlayerContentContainerViewController?
    private(set) var playerNavigationItem: PlayerNavigationItem?

    var sourceController: UIViewController? { return self.playerContentContainerViewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerContentContainerRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    func navigationItemType(for viewController: UIViewController) -> PlayerNavigationItemType? {
        guard let tabBarItem = viewController.tabBarItem else { return nil }
        return PlayerNavigationItemType(rawValue: tabBarItem.tag)
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: PlayerContentContainerViewController, navigationItem: PlayerNavigationItem?) {

        for childViewController in controller.viewControllers ?? [] {
            guard let childViewControllerNavigationItemType = navigationItemType(for: childViewController) else { continue }
            guard let navigationController = childViewController as? UINavigationController else { continue }

            switch childViewControllerNavigationItemType {
            case .video:
                guard let videoViewController = navigationController.viewControllers.first as? VideoViewController else { continue }
                let videoRouter = DefaultVideoRouter(dependencies: self.dependencies)
                videoRouter.start(controller: videoViewController)
            case .lyrics:
                guard let lyricsViewController = navigationController.viewControllers.first as? LyricsViewController else { continue }
                let lyricsRouter = DefaultLyricsRouter(dependencies: self.dependencies)
                lyricsRouter.start(controller: lyricsViewController)
            case .playlist:
                guard let playerPlaylistRootViewController = navigationController.viewControllers.first as? PlayerPlaylistRootViewController else { continue }
                let playerPlaylistRootRouter = DefaultPlayerPlaylistRootRouter(dependencies: self.dependencies)
                playerPlaylistRootRouter.start(controller: playerPlaylistRootViewController)
            case .promo:
                guard let promoViewController = navigationController.viewControllers.first as? PromoViewController else { continue }
                let promoRouter = DefaultPromoRouter(dependencies: self.dependencies)
                promoRouter.start(controller: promoViewController)
            }
        }

        playerContentContainerViewController = controller
        let vm = PlayerContentContainerControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)

        if let navigationItem = navigationItem {
            self.navigate(to: navigationItem)
        }
    }

    func stop(_ animated: Bool) {
        self.playerNavigationItem = nil
        self.playerContentContainerViewController?.dismiss(animated: animated, completion: nil)
    }
}

extension DefaultPlayerContentContainerRouter {

    func viewController(for playerNavigationItem: PlayerNavigationItem) -> UIViewController? {
        return self.playerContentContainerViewController?.viewControllers?.filter ( {
            guard let tabBarItem = $0.tabBarItem, let playerNavigationItemType = PlayerNavigationItemType(rawValue: tabBarItem.tag) else { return false }
            return playerNavigationItemType == playerNavigationItem.type
        } ).first
    }

    func navigate(to playerNavigationItem: PlayerNavigationItem) {
        guard playerNavigationItem.type != self.playerNavigationItem?.type else { self.stop(true); return }
        guard let viewController = self.viewController(for: playerNavigationItem) else { return }
        self.playerContentContainerViewController?.selectedViewController = viewController
        self.playerNavigationItem = playerNavigationItem
    }
}
