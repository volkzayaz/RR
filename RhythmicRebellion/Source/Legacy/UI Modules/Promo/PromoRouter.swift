//
//  PromoRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ForcedAuthorizationRouter: class {
    func routeToAuthorization(with authorizationType: AuthorizationType)
}

protocol PromoRouterDelegate: ForcedAuthorizationRouter {
    func navigateToPage(with url: URL)
}

protocol PromoRouter: FlowRouter, ForcedAuthorizationRouter {
    func navigateToPage(with url: URL)
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

    

    private(set) weak var viewModel: PromoViewModel?
    private(set) weak var sourceController: UIViewController?
    private(set) weak var delegate: PromoRouterDelegate?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPromoRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init( delegate: PromoRouterDelegate?) {
        
        self.delegate = delegate
    }

    func start(controller: PromoViewController) {
        sourceController = controller
        let vm = PromoViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func navigateToPage(with url: URL) {
        self.delegate?.navigateToPage(with: url)
    }

    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.delegate?.routeToAuthorization(with: authorizationType)
    }
}
