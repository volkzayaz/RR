//
//  PlayerContentContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerContentContainerRouter: FlowRouter, PlayerNavigationDelgate {
    func stop(_ animated: Bool)
}

final class DefaultPlayerContentContainerRouter:  PlayerContentContainerRouter, SegueCompatible {

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

    var dependencies: RouterDependencies

    private(set) weak var viewModel: PlayerContentContainerViewModel?
    private(set) weak var playerContentContainerViewController: PlayerContentContainerViewController?
    private(set) var playerNavigationItem: PlayerNavigationItem?

    var sourceController: UIViewController? { return self.playerContentContainerViewController }

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
            case .follow:
                guard let followViewController = navigationController.viewControllers.first as? FollowViewController else { continue }
                let followRouter = DefaultFollowRouter(dependencies: self.dependencies)
                followRouter.start(controller: followViewController)
            case .video:
                guard let videoViewController = navigationController.viewControllers.first as? VideoViewController else { continue }
                let videoRouter = DefaultVideoRouter(dependencies: self.dependencies)
                videoRouter.start(controller: videoViewController)
            case .lirycs:
                guard let lyricsViewController = navigationController.viewControllers.first as? LyricsViewController else { continue }
                let lyricsRouter = DefaultLyricsRouter(dependencies: self.dependencies)
                lyricsRouter.start(controller: lyricsViewController)
            case .playList:
                guard let playlistViewController = navigationController.viewControllers.first as? PlaylistViewController else { continue }
                let playlistRouter = DefaultPlaylistRouter(dependencies: self.dependencies)
                playlistRouter.start(controller: playlistViewController)
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
