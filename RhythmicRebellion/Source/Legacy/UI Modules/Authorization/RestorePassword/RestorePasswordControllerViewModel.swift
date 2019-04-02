//
//  RestorePasswordControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator

struct RestoreUserCredentials {
    let email: String
    let password: String = ""
}

final class RestorePasswordControllerViewModel: RestorePasswordViewModel {

    // MARK: - Public properties -

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: RestorePasswordViewModelDelegate?
    private(set) weak var router: RestorePasswordRouter?
    private(set) weak var restApiService: RestApiService?

    private var initialEmail: String?

    private(set) var isRestorePasswordSucced: Bool = false

    private let validator: Validator

    private(set) var restorePasswordErrorDescription: String?

    private var emailField: ValidatableField?

    // MARK: - Lifecycle -

    init(router: RestorePasswordRouter, restApiService: RestApiService, email: String?)  {
        self.router = router
        self.restApiService = restApiService
        self.validator = Validator()
        self.initialEmail = email
    }

    func load(with delegate: RestorePasswordViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
                self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })

        self.delegate?.refreshEmailField(with: initialEmail)

        self.delegate?.refreshUI()
    }

    func registerEmailField(_ emailField: ValidatableField) {

        let emailRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Email field is required.",
                                                                          comment: "Email validataion message")),
                                  EmailRule(message: NSLocalizedString("The Email is wrong",
                                                                       comment: "Email validataion message"))]
        self.validator.registerField(emailField, rules: emailRules)

        self.emailField = emailField

        if emailField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: emailField, didValidate: nil)
        } else {
            self.validator.validateField(emailField) { (validationError) in }
        }
    }

    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "email": return self.emailField
        default: break
        }

        return nil
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }
    }

    func restorePassword() {

        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText else { return }

            let _ =
            UserRequest.restorePassword(email: email)
                .rx.response(type: FanForgotPasswordResponse.self)
                .subscribe(onSuccess: { (_) in
                    
                    self.isRestorePasswordSucced = true
                    self.delegate?.refreshUI()
                    
                }, onError: { error in
                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                        self.delegate?.show(error: error)
                        return
                    }
                    
                    switch appErrorGroup {
                    case RestApiServiceError.serverError( let errorDescription, let errors):
                        self.restorePasswordErrorDescription = errorDescription
                        for (key, errorStrings) in errors {
                            guard let validatebleField = self.validatebleField(for: key), let validatebleFieldErrorString = errorStrings.first else { continue }
                            
                            let validationError = ValidationError(field: validatebleField, errorLabel: nil, error: validatebleFieldErrorString)
                            self.delegate?.refreshField(field: validatebleField, didValidate: validationError)
                        }
                        
                    default:
                        self.delegate?.show(error: error)
                    }
                    
                    self.delegate?.refreshUI()
                })
            
        }
    }
}
