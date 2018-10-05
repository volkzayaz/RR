//
//  PlayerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

public enum PlayerNavigationItemType: Int {
    case video
    case lyrics
    case playlist
    case promo
}

public class PlayerNavigationItem {

    var type: PlayerNavigationItemType

    private weak var playerViewController: PlayerViewController?

    fileprivate init(playerViewController: PlayerViewController, type: PlayerNavigationItemType) {
        self.type = type
        self.playerViewController = playerViewController
    }

    deinit {
        self.playerViewController?.unselect(self)
    }
}

protocol PlayerNavigationDelgate: class {
    func navigate(to playerNavigationItem: PlayerNavigationItem)
    func navigateToAuthorization()
}

protocol PlayerRouter: FlowRouter {

    func navigate(to playerNavigationItemType: PlayerNavigationItemType)
    func navigateToAuthorization()
}

final class DefaultPlayerRouter:  PlayerRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: PlayerViewModel?
    private(set) weak var playerViewController: PlayerViewController?
    private(set) weak var navigationDelegate: PlayerNavigationDelgate?

    var sourceController: UIViewController? { return self.playerViewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPlayerRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies, navigationDelegate: PlayerNavigationDelgate) {
        self.dependencies = dependencies
        self.navigationDelegate = navigationDelegate
    }

    func start(controller: PlayerViewController) {
        playerViewController = controller
        let vm = PlayerControllerViewModel(router: self, application: self.dependencies.application, player: self.dependencies.player)
        controller.configure(viewModel: vm, router: self)
    }
}

extension DefaultPlayerRouter {

    func navigate(to playerNavigationItemType: PlayerNavigationItemType) {
        guard let playerViewController = self.playerViewController else { return }
        self.navigationDelegate?.navigate(to: PlayerNavigationItem(playerViewController: playerViewController, type: playerNavigationItemType))
    }

    func navigateToAuthorization() {
        self.navigationDelegate?.navigateToAuthorization()
    }
}

