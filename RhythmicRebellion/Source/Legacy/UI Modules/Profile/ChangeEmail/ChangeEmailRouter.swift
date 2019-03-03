//
//  ChangeEmailRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ChangeEmailRouter: FlowRouter {
    func restart()
}

final class DefaultChangeEmailRouter:  ChangeEmailRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: ChangeEmailViewModel?
    private(set) weak var changeEmailViewController: ChangeEmailViewController?

    var sourceController: UIViewController? { return self.changeEmailViewController }


    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultChangeEmailRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: ChangeEmailViewController) {
        changeEmailViewController = controller
        let vm = ChangeEmailControllerViewModel(router: self, restApiService: self.dependencies.restApiService)
        controller.configure(viewModel: vm, router: self)
    }

    func restart() {
        let vm = ChangeEmailControllerViewModel(router: self, restApiService: self.dependencies.restApiService)
        self.changeEmailViewController?.configure(viewModel: vm, router: self)
    }
}
