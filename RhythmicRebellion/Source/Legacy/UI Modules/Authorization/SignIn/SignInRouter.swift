//
//  SignInRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class SignInRouter: FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case restorePassword = "RestorePasswordSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showRestorePassword(email: String?)

        var identifier: SegueDestinationList {
            switch self {
            case .showRestorePassword: return SegueList.restorePassword
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

    func prepare(for destination: SignInRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .showRestorePassword(let email):
            guard let restorePasswordViewController = segue.destination as? RestorePasswordViewController else { fatalError("Incorrect controller for restorePassword") }
            let restorePasswordRouter = DefaultRestorePasswordRouter(dependencies: dependencies)
            restorePasswordRouter.start(controller: restorePasswordViewController, email: email)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: SignInViewController) {
        signInViewController = controller
        let vm = SignInViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }

    func showRestorePassword(email: String?) {
        self.perform(segue: .showRestorePassword(email: email))
    }

    func restart() {
        let vm = SignInViewModel(router: self)
        signInViewController?.configure(viewModel: vm, router: self)
    }

}
