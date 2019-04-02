//
//  ChangeEmailControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator

final class ChangeEmailControllerViewModel: ChangeEmailViewModel {

    // MARK: - Public properties -

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: ChangeEmailViewModelDelegate?
    private(set) weak var router: ChangeEmailRouter?
    private(set) weak var restApiService: RestApiService?

    private(set) var changeEmailErrorDescription: String?

    private(set) var isChangeEmailSucced: Bool = false

    private let validator: Validator
    private var newEmailField: ValidatableField?
    private var currentPasswordField: ValidatableField?

    // MARK: - Lifecycle -

    init(router: ChangeEmailRouter, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService
        
        self.validator = Validator()
    }

    func load(with delegate: ChangeEmailViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
                self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })

        self.delegate?.refreshUI()
    }

    func registerNewEmailField(_ newEmailField: ValidatableField) {

        let newEmailRules: [Rule] = [RequiredRule(message: "The field is required"),
                                     EmailRule(message: "Email is wrong")]
        self.validator.registerField(newEmailField, rules: newEmailRules)

        self.newEmailField = newEmailField
        
        if newEmailField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: newEmailField, didValidate: nil)
        } else {
            self.validator.validateField(newEmailField) { (validationError) in }
        }
    }

    func registerCurrentPasswordField(_ currentPasswordField: ValidatableField) {
        let passwordRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Current Password field is required.",
                                                                             comment: "Password validataion message")),
                                     MinLengthRule(length: 6,
                                                   message: NSLocalizedString("The Current Password must be at least %ld characters",
                                                                              comment: "Password validataion template"))]
        self.validator.registerField(currentPasswordField, rules: passwordRules)

        self.currentPasswordField = currentPasswordField

        self.delegate?.refreshField(field: currentPasswordField, didValidate: nil)
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }
    }

    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "email": return self.newEmailField
        case "current_password": return self.currentPasswordField
        default: break
        }

        return nil
    }


    func changeEmail() {

        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let newEmail = self.newEmailField?.validationText,
                let currentPassword = self.currentPasswordField?.validationText else { return }

            let _ =
            UserRequest.changeEmail(to: newEmail, currentPassword: currentPassword)
                .rx.rawJSONResponse()
                .subscribe(onSuccess: { (_) in
                    self.isChangeEmailSucced = true
                    self.delegate?.refreshUI()
                }, onError: { error in
                    
                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                        self.delegate?.show(error: error)
                        return
                    }
                    
                    switch appErrorGroup {
                    case RestApiServiceError.serverError( let errorDescription, let errors):
                        self.changeEmailErrorDescription = errorDescription
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

    func restart() {
        self.router?.restart()
    }

}
