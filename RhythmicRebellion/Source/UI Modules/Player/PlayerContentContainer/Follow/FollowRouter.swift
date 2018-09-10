//
//  FollowRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol FollowRouter: FlowRouter {
}

final class DefaultFollowRouter:  FollowRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: FollowViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultFollowRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }


    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: FollowViewController) {
        sourceController = controller
        let vm = FollowControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
