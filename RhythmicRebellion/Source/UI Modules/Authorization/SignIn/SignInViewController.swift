//
//  SignInViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator

final class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: MFTextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: MFTextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    @IBOutlet weak var signInErrorLabel: UILabel!
    // MARK: - Public properties -

    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: SignInViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

//        self.emailTextField.layer.cornerRadius = 2.0
//        self.emailTextField.clipsToBounds = true
        self.emailTextField.textColor = self.viewModel.defaultTextColor
        self.emailTextField.placeholderAnimatesOnFocus = true;

//        self.passwordTextField.layer.cornerRadius = 2.0
//        self.passwordTextField.clipsToBounds = true
        self.passwordTextField.textColor = self.viewModel.defaultTextColor
        self.passwordTextField.placeholderAnimatesOnFocus = true;

        self.viewModel.load(with: self)

        self.viewModel.registerEmailField(emailField: self.emailTextField)
        self.viewModel.registerPasswordField(passwordField: self.passwordTextField)

        #if DEBUG
//        self.emailTextField.text = "alexander@olearis.com"
//        self.passwordTextField.text = "ngrx2Fan"
        #else
//        self.emailTextField.text = "alena@olearis.com"
//        self.passwordTextField.text = "Olearistest1"
        #endif
    }

    // MARK: - Actions

    @IBAction func onSignIn(sender: Any) {

        self.view.endEditing(true)
        self.viewModel.signIn()
    }

    // MARK: - UITextFieldDelegate

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(field: textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.viewModel.validateField(field: textField)

        if textField == self.emailTextField {
            self.passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            self.onSignIn(sender: self)
        }

        return true
    }
}

// MARK: - Router -
extension SignInViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension SignInViewController: SignInViewModelDelegate {

    func refresh(textField: MFTextField, errorLabel: UILabel, withValidationError validationError: ValidationError?) {

        guard let error = validationError else {
            errorLabel.text = ""
            errorLabel.isHidden = true

            textField.tintColor = self.viewModel.defaultTintColor
            textField.defaultPlaceholderColor = self.viewModel.defaultTextColor
            textField.placeholderColor = self.viewModel.defaultTextColor

            return
        }

        errorLabel.text = error.errorMessage
        errorLabel.isHidden = false

        textField.tintColor = self.viewModel.errorColor
        textField.defaultPlaceholderColor = self.viewModel.errorColor
        textField.placeholderColor = self.viewModel.errorColor
    }

    func refreshUI() {
        self.signInErrorLabel.text = self.viewModel.signInErrorDescription
        self.signInErrorLabel.isHidden = self.signInErrorLabel.text?.isEmpty ?? true
    }

    
    func refreshEmailField(field: ValidatableField, didValidate validationError: ValidationError?) {
        self.refresh(textField: self.emailTextField, errorLabel: self.emailErrorLabel, withValidationError: validationError)
    }

    func refreshPasswordField(field: ValidatableField, didValidate validationError: ValidationError?) {
        self.refresh(textField: self.passwordTextField, errorLabel: self.passwordErrorLabel, withValidationError: validationError)
    }

    func show(error: Error) {

        let errorAlertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
        errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK Title for AlertAction"), style: .cancel, handler: { (action) in
            errorAlertController.dismiss(animated: true, completion: nil)
        }))

        self.present(errorAlertController, animated: true, completion: nil)
    }
}
