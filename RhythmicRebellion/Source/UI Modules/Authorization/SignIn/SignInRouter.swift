//
//  SignInRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol SignInRouter: FlowRouter {

    func restart()
}

final class DefaultSignInRouter:  SignInRouter, FlowRouterSegueCompatible {

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

    private(set) weak var viewModel: SignInViewModel?
    private(set) weak var signInViewController: SignInViewController?

    var sourceController: UIViewController? { return signInViewController}

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultSignInRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: SignInViewController) {
        signInViewController = controller
        let vm = SignInControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }

    func restart() {
        let vm = SignInControllerViewModel(router: self, application: self.dependencies.application)
        signInViewController?.configure(viewModel: vm, router: self)
    }

}
