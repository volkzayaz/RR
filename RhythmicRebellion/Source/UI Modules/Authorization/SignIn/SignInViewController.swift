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

class SignInView: UIView {

    override var intrinsicContentSize: CGSize {
        return super.intrinsicContentSize
    }
}

final class SignInViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: MFTextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: MFTextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    @IBOutlet weak var signInErrorLabel: UILabel!

    // MARK: - Public properties -
    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!

    private var applicationWillEnterForegroundObserver: NSObjectProtocol?

    deinit {
        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }
    }

    // MARK: - Configuration -

    func configure(viewModel: SignInViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded {
            self.passwordTextField.text = nil
            self.bindViewModel()
        }
    }

    func bindViewModel() {
        self.viewModel.load(with: self)

        self.viewModel.registerEmailField(emailField: self.emailTextField)
        self.viewModel.registerPasswordField(passwordField: self.passwordTextField)
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView.isScrollEnabled = false
        self.preferredContentSize = CGSize(width: self.view.bounds.size.width, height: 368.0)

        self.emailTextField.textColor = self.viewModel.defaultTextColor
        self.emailTextField.placeholderAnimatesOnFocus = true;

        self.passwordTextField.textColor = self.viewModel.defaultTextColor
        self.passwordTextField.placeholderAnimatesOnFocus = true;

        self.bindViewModel()

        #if DEBUG
//        self.emailTextField.text = "alexander@olearis.com"
//        self.passwordTextField.text = "ngrx2Fan"
        #else
//        self.emailTextField.text = "alena@olearis.com"
//        self.passwordTextField.text = "Olearistest1"
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationWillEnterForeground, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.applicationWillEnterForeground(notification: notification)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }
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

    // MARK: - Notifications

    func applicationWillEnterForeground(notification: Notification) {
        self.viewModel.restart()
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
}