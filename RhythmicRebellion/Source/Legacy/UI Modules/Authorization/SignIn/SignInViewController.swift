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

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var emailTextField: MFTextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordTextField: MFTextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    @IBOutlet weak var signInErrorLabel: UILabel!

    @IBOutlet weak var facebookButton: UIButton! {
        didSet {
            //facebookButton.isHidden = true
        }
    }
    
    // MARK: - Public properties -
    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!

    private var applicationWillEnterForegroundObserver: NSObjectProtocol?
    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    deinit {
        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
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

        self.applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.applicationWillEnterForeground(notification: notification)
        }

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardDidShow(notification: notification)
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardWillHide(notification: notification)
        }
        
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }

    // MARK: - Actions

    @IBAction func onSignIn(sender: Any?) {

        self.view.endEditing(true)
        self.viewModel.signIn()
    }

    @IBAction func onRestorePassword(sender: Any?) {
        self.viewModel.resorePassword()
    }
    
    @IBAction func joinWithFacebook(_ sender: Any) {
        viewModel.joinWithFacebook()
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

    @IBAction func textFieldEditingChange(textField: UITextField) {

        let textFieldFrame = self.contentView.convert(textField.frame, to: self.scrollView)
        let scrollViewBounds = self.scrollView.bounds.inset(by: self.scrollView.contentInset)

        if scrollViewBounds.contains(textFieldFrame) == false {
            scrollView.scrollRectToVisible(textFieldFrame, animated: true)
        }
    }

    // MARK: - Notifications

    func applicationWillEnterForeground(notification: Notification) {
        self.viewModel.restart()
    }

    func keyboardDidShow(notification: Notification) {
        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)

        let bottomInset = self.view.bounds.maxY - keyboardFrame.minY
        if bottomInset > 0 {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
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

    func refreshEmailField(with email: String?) {
        self.emailTextField.text = email
    }
}

// MARK: - AuthorizationChildViewController -
extension SignInViewController: AuthorizationChildViewController {
    var authorizationType: AuthorizationType { return .signIn }
}

