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
    case signIn
    case signUp

    var identifier: String {
        switch self {
        case .signIn: return "SignInViewControllerIdentifier"
        case .signUp: return "SignUpViewControllerIdentifier"
        }
    }
}

protocol AuthorizationChildViewController {
    var authorizationType: AuthorizationType { get }
}

protocol AuthorizationRouter: FlowRouter {
    func change(authorizationType: AuthorizationType)
}

final class DefaultAuthorizationRouter:  AuthorizationRouter, FlowRouterSegueCompatible {

    typealias ChildViewController = UIViewController & AuthorizationChildViewController

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case signIn = "SignInSegueIdentifier"
        case signUp = "SignUpSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case signIn
        case signUp

        var identifier: SegueDestinationList {
            switch self {
            case .signIn: return SegueList.signIn
            case .signUp: return SegueList.signUp
            }
        }

        init?(destinationList: SegueDestinationList) {
            switch destinationList as? SegueList {
            case .signIn?: self = .signIn
            case .signUp?: self = .signUp
            default: fatalError("UPS!")
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: AuthorizationViewModel?
    private(set) weak var authorizationViewController: AuthorizationViewController?

    var sourceController: UIViewController? { return authorizationViewController }


    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(viewController: UIViewController) {

        switch viewController {
        case let signInViewController as SignInViewController:
            let signInRouter = SignInRouter(dependencies: self.dependencies)
            signInRouter.start(controller: signInViewController)

        case let signUpViewController as SignUpViewController:
            let signUpRouter = DefaultSignUpRouter(dependencies: self.dependencies)
            signUpRouter.start(controller: signUpViewController)

        default: break
        }
    }

    func prepare(for destination: DefaultAuthorizationRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .signIn:
            guard let signInViewController = segue.destination as? SignInViewController else { fatalError("Incorrect controller for SignInSegueIdentifier") }
            prepare(viewController: signInViewController)
            self.authorizationViewController?.selectedViewController = signInViewController

        case .signUp:
            guard let signUpViewController = segue.destination as? SignUpViewController else { fatalError("Incorrect controller for SignUpSegueIdentifier") }
            self.prepare(viewController: signUpViewController)
            self.authorizationViewController?.selectedViewController = signUpViewController
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AuthorizationViewController) {
        authorizationViewController = controller
        let vm = AuthorizationControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)

        for childViewController in self.authorizationViewController?.children ?? [] {
            self.prepare(viewController: childViewController)
        }

        self.authorizationViewController?.navigationController?.popToRootViewController(animated: false)
    }

    func instantiateViewController(for authorizationType: AuthorizationType) -> ChildViewController? {
        guard let viewController = self.authorizationViewController?.storyboard?.instantiateViewController(withIdentifier: authorizationType.identifier) as? ChildViewController else { return nil }
        
        return viewController
    }

    func viewController(for authorizaionType: AuthorizationType) -> ChildViewController? {
        guard let authorizationViewController = self.authorizationViewController else { return nil }

        guard let childViewControllers = authorizationViewController.children as? [ChildViewController], let viewControllerForAuthorizationType = childViewControllers.first(where: { (viewController) -> Bool in
            switch authorizaionType {
            case .signIn:
                guard let _ = viewController as? SignInViewController else { return false }
                return true

            case .signUp:
                guard let _ = viewController as? SignUpViewController else { return false }
                return true
            }
        }) else { return self.instantiateViewController(for: authorizaionType) }



        return viewControllerForAuthorizationType
    }


    func change(authorizationType: AuthorizationType) {

        guard let authorizationViewController = self.authorizationViewController, let selectedViewController = authorizationViewController.selectedViewController else { return }
        guard selectedViewController.authorizationType != authorizationType else { return }
        guard let viewControllerForAuthorizationType = self.viewController(for: authorizationType) else { return }

        self.prepare(viewController: viewControllerForAuthorizationType)

        if viewControllerForAuthorizationType.parent != authorizationViewController {
            authorizationViewController.addChild(viewControllerForAuthorizationType)
        }

        viewControllerForAuthorizationType.view.translatesAutoresizingMaskIntoConstraints = false

        authorizationViewController.transition(from: selectedViewController,
                                               to: viewControllerForAuthorizationType,
                                               duration: 0.0,
                                               options: [],
                                               animations: nil,
                                               completion: { (success) in
                                                guard success else { return }
                                                NSLayoutConstraint.activate([viewControllerForAuthorizationType.view.topAnchor.constraint(equalTo:
                                                                                authorizationViewController.containerView.topAnchor),
                                                                             viewControllerForAuthorizationType.view.leftAnchor.constraint(equalTo: authorizationViewController.containerView.leftAnchor),
                                                                             viewControllerForAuthorizationType.view.bottomAnchor.constraint(equalTo: authorizationViewController.containerView.bottomAnchor),
                                                                             viewControllerForAuthorizationType.view.rightAnchor.constraint(equalTo: authorizationViewController.containerView.rightAnchor)])
                                                authorizationViewController.selectedViewController = viewControllerForAuthorizationType
        })
    }

}
