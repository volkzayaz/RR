//
//  PlayerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerNavigationItemDelegate: class {
    func refreshUI(for navigationItem: PlayerNavigationItem, isSelected: Bool)
}

public class PlayerNavigationItem {

    public enum NavigationType: Int {
        case video
        case lyrics
        case playlist
        case promo
    }

    var type: NavigationType

    var isSelected: Bool {
        didSet { self.delegate?.refreshUI(for: self, isSelected: self.isSelected) }
    }

    private weak var delegate: PlayerNavigationItemDelegate?

    fileprivate init(type: NavigationType, delegate: PlayerNavigationItemDelegate) {
        self.type = type
        self.delegate = delegate
        self.isSelected = false
    }
}

protocol PlayerNavigationDelgate: ForcedAuthorizationRouter {
    func navigate(to playerNavigationItem: PlayerNavigationItem)
}

protocol PlayerRouter: FlowRouter, ForcedAuthorizationRouter {

    func navigate(to playerNavigationItemType: PlayerNavigationItem.NavigationType)
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
        let vm = PlayerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
}

extension DefaultPlayerRouter {

    func navigate(to playerNavigationItemType: PlayerNavigationItem.NavigationType) {
        guard let playerViewController = self.playerViewController else { return }
        self.navigationDelegate?.navigate(to: PlayerNavigationItem(type: playerNavigationItemType, delegate: playerViewController))
    }

    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.navigationDelegate?.routeToAuthorization(with: authorizationType)
    }
}

