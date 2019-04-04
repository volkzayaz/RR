//
//  ProfileRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ProfileRouter: FlowRouter {

    func navigateToProfileSettings()
    func navigateToChangeEmail()
    func navigateToChangePassword()
}

final class DefaultProfileRouter:  ProfileRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case profileSettings = "ProfileSettingsSegueIdentifier"
        case changeEmail = "ChangeEmailSegueIdentifier"
        case changePassword = "ChangePasswordSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case profileSettings
        case changeEmail
        case changePassword

        var identifier: SegueDestinationList {
            switch self {
            case .profileSettings: return SegueList.profileSettings
            case .changeEmail: return SegueList.changeEmail
            case .changePassword: return SegueList.changePassword
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: ProfileViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultProfileRouter.SegueActions, segue: UIStoryboardSegue) {
        switch destination {
        case .profileSettings:
            guard let profileSettingsViewController = segue.destination as? ProfileSettingsViewController else { fatalError("Incorrect controller for ProfileSettingsSegueIdentifier") }
            let profileSettingsRouter = DefaultProfileSettingsRouter(dependencies: self.dependencies)
            profileSettingsRouter.start(controller: profileSettingsViewController)

        case .changeEmail:
            guard let changeEmailViewController = segue.destination as? ChangeEmailViewController else { fatalError("Incorrect controller for ChangeEmailSegueIdentifier") }
            let changeEmailRouter = DefaultChangeEmailRouter(dependencies: self.dependencies)
            changeEmailRouter.start(controller: changeEmailViewController)

        case .changePassword:
            guard let changePasswordViewController = segue.destination as? ChangePasswordViewController else { fatalError("Incorrect controller for ChangePasswordSegueIdentifier") }
            let changePasswordRouter = DefaultChangePasswordRouter(dependencies: self.dependencies)
            changePasswordRouter.start(controller: changePasswordViewController)
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: ProfileViewController) {
        sourceController = controller
        let vm = ProfileControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)

        for viewController in controller.navigationController?.viewControllers ?? [] {
            switch viewController {
            case let changePasswordViewController as ChangePasswordViewController:
                let changePasswordRouter = DefaultChangePasswordRouter(dependencies: self.dependencies)
                changePasswordRouter.start(controller: changePasswordViewController)

            case let changeEmailViewController as ChangeEmailViewController:
                let changeEmailRouter = DefaultChangeEmailRouter(dependencies: self.dependencies)
                changeEmailRouter.start(controller: changeEmailViewController)

            default: break
            }
        }
    }

    func navigateToProfileSettings() {
        self.perform(segue: .profileSettings)
    }

    func navigateToChangeEmail() {
        self.perform(segue: .changeEmail)
    }

    func navigateToChangePassword() {
        self.perform(segue: .changePassword)
    }
}

