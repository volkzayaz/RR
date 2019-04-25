//
//  PlayerContentContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerContentNavigationDelgate: PromoRouterDelegate, LyricsKaraokeRouterDelegate {
}


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
    private(set) weak var navigationDelegate: PlayerContentNavigationDelgate?

    var sourceController: UIViewController? { return self.playerContentContainerViewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerContentContainerRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    func navigationItemType(for viewController: UIViewController) -> PlayerNavigationItem.NavigationType? {
        guard let tabBarItem = viewController.tabBarItem else { return nil }
        return PlayerNavigationItem.NavigationType(rawValue: tabBarItem.tag)
    }

    init(dependencies: RouterDependencies, navigationDelegate: PlayerContentNavigationDelgate?) {
        self.dependencies = dependencies
        self.navigationDelegate = navigationDelegate
    }

    func start(controller: PlayerContentContainerViewController, navigationItem: PlayerNavigationItem?) {

        for childViewController in controller.viewControllers ?? [] {
            guard let childViewControllerNavigationItemType = navigationItemType(for: childViewController) else { continue }

            switch childViewControllerNavigationItemType {
            case .video:
                guard let navigationController = childViewController as? UINavigationController,
                    let x = navigationController.viewControllers.first as? VideoViewController else { continue }
                
                x.viewModel = VideoViewModel(router: VideoRouter(owner: x))
                
            case .lyrics:
                guard let lyricsKaraokeViewController = childViewController as? LyricsKaraokeViewController else { continue }
                let lyricsKaraokeRouter = DefaultLyricsKaraokeRouter(dependencies: self.dependencies, delegate: self.navigationDelegate)
                lyricsKaraokeRouter.start(controller: lyricsKaraokeViewController)
            case .playlist:
                guard let navigationController = childViewController as? UINavigationController,
                    let playerPlaylistRootViewController = navigationController.viewControllers.first as? PlayerPlaylistRootViewController else { continue }
                let playerPlaylistRootRouter = DefaultPlayerPlaylistRootRouter(dependencies: self.dependencies)
                playerPlaylistRootRouter.start(controller: playerPlaylistRootViewController)
            case .promo:
                guard let navigationController = childViewController as? UINavigationController,
                    let promoViewController = navigationController.viewControllers.first as? PromoViewController else { continue }
                let promoRouter = DefaultPromoRouter(dependencies: self.dependencies, delegate: self.navigationDelegate)
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
        self.playerContentContainerViewController?.dismiss(animated: animated, completion: {
            self.playerNavigationItem?.isSelected = false
        })
    }
}

extension DefaultPlayerContentContainerRouter {

    func viewController(for playerNavigationItem: PlayerNavigationItem) -> UIViewController? {
        return self.playerContentContainerViewController?.viewControllers?.filter ( {
            guard let tabBarItem = $0.tabBarItem, let playerNavigationItemType = PlayerNavigationItem.NavigationType(rawValue: tabBarItem.tag) else { return false }
            return playerNavigationItemType == playerNavigationItem.type
        } ).first
    }

    func navigate(to playerNavigationItem: PlayerNavigationItem) {
        guard playerNavigationItem.type != self.playerNavigationItem?.type else { self.stop(true); return }
        guard let viewController = self.viewController(for: playerNavigationItem) else { return }
        self.playerContentContainerViewController?.selectedViewController = viewController

        self.playerNavigationItem?.isSelected = false
        self.playerNavigationItem = playerNavigationItem
        self.playerNavigationItem?.isSelected = true
    }
}
