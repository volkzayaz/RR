//
//  ChangePasswordRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/22/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ChangePasswordRouter: FlowRouter {
    func restart()
}

final class DefaultChangePasswordRouter:  ChangePasswordRouter, FlowRouterSegueCompatible {

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
    
    private(set) weak var viewModel: ChangePasswordViewModel?
    private(set) weak var changePasswordViewController: ChangePasswordViewController?

    var sourceController: UIViewController? { return self.changePasswordViewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultChangePasswordRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(controller: ChangePasswordViewController) {
        changePasswordViewController = controller
        let vm = ChangePasswordControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func restart() {
        let vm = ChangePasswordControllerViewModel(router: self)
        self.changePasswordViewController?.configure(viewModel: vm, router: self)
    }
}
