//
//  SignInViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
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

        viewModel.load(with: self)

        self.viewModel.registerEmailField(emailField: self.emailTextField, emailErrorLabel: self.emailErrorLabel)
        self.viewModel.registerPasswordField(passwordField: self.passwordTextField, passwordErrorLabel: self.passwordErrorLabel)

        #if DEBUG
        self.emailTextField.text = "alexander@olearis.com"
        self.passwordTextField.text = "ngrx2Fan"
//        self.passwordTextField.text = "ngrx2Fan1111"
        #else
        self.emailTextField.text = "alena@olearis.com"
        self.passwordTextField.text = "Olearistest1"
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

    func refreshUI() {
        self.signInErrorLabel.text = self.viewModel.signInErrorDescription
        self.signInErrorLabel.isHidden = self.signInErrorLabel.text?.isEmpty ?? true
    }

}
