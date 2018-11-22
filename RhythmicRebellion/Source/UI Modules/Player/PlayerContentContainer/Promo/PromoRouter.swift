//
//  PromoRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PromoNavigationDelegate: class {
    func navigateToPage(with url: URL)
    func navigateToAuthorization()
}

protocol PromoRouter: FlowRouter {
    func navigateToPage(with url: URL)
    func navigateToAuthorization()
}

final class DefaultPromoRouter:  PromoRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: PromoViewModel?
    private(set) weak var sourceController: UIViewController?
    private(set) weak var navigationDelegate: PromoNavigationDelegate?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPromoRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies, navigationDelegate: PromoNavigationDelegate?) {
        self.dependencies = dependencies
        self.navigationDelegate = navigationDelegate
    }

    func start(controller: PromoViewController) {
        sourceController = controller
        let vm = PromoControllerViewModel(router: self, application: self.dependencies.application, player: self.dependencies.player)
        controller.configure(viewModel: vm, router: self)
    }

    func navigateToPage(with url: URL) {
        self.navigationDelegate?.navigateToPage(with: url)
    }

    func navigateToAuthorization() {
        self.navigationDelegate?.navigateToAuthorization()
    }
}
