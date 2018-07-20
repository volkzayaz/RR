//
//  SignInControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator

struct SignInUserCredentials: UserCredentials {
    let email: String
    let password: String
}

final class SignInControllerViewModel: SignInViewModel {

    // MARK: - Public properties

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041702, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: SignInViewModelDelegate?
    private(set) weak var router: SignInRouter?
    private(set) weak var application: Application?

    private(set) var signInErrorDescription: String?

    private let validator: Validator
    private var emailField: ValidatableField?
    private var passwordField: ValidatableField?

    // MARK: - Lifecycle -

    init(router: SignInRouter, application: Application) {
        self.router = router
        self.application = application
        self.validator = Validator()
    }

    func load(with delegate: SignInViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            if validationRule.field === self.emailField {
                self.delegate?.refreshEmailField(field: validationRule.field, didValidate: nil)
            } else if validationRule.field === self.passwordField {
                self.delegate?.refreshPasswordField(field: validationRule.field, didValidate: nil)
            }
        }, error:{ (validationError) -> Void in
            if validationError.field === self.emailField {
                self.delegate?.refreshEmailField(field: validationError.field, didValidate: validationError)
            } else if validationError.field === self.passwordField {
                self.delegate?.refreshPasswordField(field: validationError.field, didValidate: validationError)
            }
        })
    }

    func registerEmailField(emailField: ValidatableField) {

        self.emailField = emailField
        let emailRules: [Rule] = [RequiredRule(message: "The field is required"),
                                  EmailRule(message: "Email is wrong")]
        self.validator.registerField(emailField, rules: emailRules)

        self.delegate?.refreshEmailField(field: emailField, didValidate: nil)
    }

    func registerPasswordField(passwordField: ValidatableField) {
        self.passwordField = passwordField
        let passwordRules: [Rule] = [RequiredRule(message: "The password field is required")]
        self.validator.registerField(passwordField, rules: passwordRules)

        self.delegate?.refreshPasswordField(field: passwordField, didValidate: nil)
    }

    func validateField(field: ValidatableField) {
        self.validator.validateField(field) { (validationError) in }
    }

    func signIn() {
        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText, let password = self.passwordField?.validationText else { return }

            let signInUserCredentials = SignInUserCredentials(email: email, password: password)

            self.application?.signIn(with: signInUserCredentials, completion: { [weak self] (error) in

                guard let error = error else { return }
                guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                    self?.delegate?.show(error: error)
                    return
                }

                switch appErrorGroup {
                case RestApiServiceError.serverError( _, let errors):
                    self?.signInErrorDescription = errors["email"]?.first
                default:
                    self?.delegate?.show(error: error)
                }

                self?.delegate?.refreshUI()
            })
        }
    }
}
