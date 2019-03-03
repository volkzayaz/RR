//
//  RestorePasswordRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol RestorePasswordRouter: FlowRouter {
}

final class DefaultRestorePasswordRouter:  RestorePasswordRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: RestorePasswordViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultRestorePasswordRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: RestorePasswordViewController, email: String?) {
        sourceController = controller
        let vm = RestorePasswordControllerViewModel(router: self, restApiService: self.dependencies.restApiService, email: email)
        controller.configure(viewModel: vm, router: self)
    }
}
