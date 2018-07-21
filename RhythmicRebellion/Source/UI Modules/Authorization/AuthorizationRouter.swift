//
//  AuthorizationRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum AuthorizationType: Int {
    case unknown
    case signIn
    case signUp
}

protocol AuthorizationRouter: FlowRouter {
}

final class DefaultAuthorizationRouter:  AuthorizationRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case signIn

        var identifier: String {
            switch self {
            case .signIn: return "SignInSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "SignInSegueIdentifier": return .signIn
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: AuthorizationViewModel?
    private(set) weak var authorizationViewController: AuthorizationViewController?

    var sourceController: UIViewController? { return authorizationViewController }

    private(set) var authorizationViewControllers = [AuthorizationType : UIViewController]()

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .signIn:
            guard let signInViewController = segue.destination as? SignInViewController else { fatalError("Incorrect controller for SignInSegueIdentifier") }
            let signInRouter = DefaultSignInRouter(dependencies: self.dependencies)
            signInRouter.start(controller: signInViewController)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AuthorizationViewController) {
        authorizationViewController = controller
        let vm = AuthorizationControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)

        for childViweController in controller.childViewControllers {
            if let signInViewController = childViweController as? SignInViewController {
                let signInRouter = DefaultSignInRouter(dependencies: self.dependencies)
                signInRouter.start(controller: signInViewController)
            }
        }
    }
}
