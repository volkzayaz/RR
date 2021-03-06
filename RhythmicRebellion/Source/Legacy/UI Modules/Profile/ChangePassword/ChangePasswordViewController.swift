//
//  ChangePasswordViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/22/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator

final class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var changePasswordSuccedLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var changePasswordErrorLabel: UILabel!
    @IBOutlet weak var currentPasswordTextField: MFTextField!
    @IBOutlet weak var currentPasswordErrorLabel: UILabel!
    @IBOutlet weak var newPasswordTextField: MFTextField!
    @IBOutlet weak var newPasswordErrorLabel: UILabel!
    @IBOutlet weak var confirmPasswordTextField: MFTextField!
    @IBOutlet weak var confirmPasswordErrorLabel: UILabel!

    // MARK: - Public properties -

    private(set) var viewModel: ChangePasswordViewModel!
    private(set) var router: FlowRouter!

    private var applicationWillEnterForegroundObserver: NSObjectProtocol?
    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?


    // MARK: - Configuration -

    func configure(viewModel: ChangePasswordViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded {
            
            self.currentPasswordTextField.text = nil
            self.newPasswordTextField.text = nil
            self.confirmPasswordTextField.text = nil

            self.bindViewModel()
        }
    }

    func bindViewModel() {
        viewModel.load(with: self)

        self.viewModel.registerCurrentPasswordField(self.currentPasswordTextField)
        self.viewModel.registerNewPasswordField(self.newPasswordTextField)
        self.viewModel.registerConfirmPasswordField(self.confirmPasswordTextField, newPasswordField: self.newPasswordTextField)
    }


    // MARK: - Lifecycle -

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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.currentPasswordTextField.textColor = self.viewModel.defaultTextColor
        self.currentPasswordTextField.placeholderAnimatesOnFocus = true;
        self.newPasswordTextField.textColor = self.viewModel.defaultTextColor
        self.newPasswordTextField.placeholderAnimatesOnFocus = true;
        self.confirmPasswordTextField.textColor = self.viewModel.defaultTextColor
        self.confirmPasswordTextField.placeholderAnimatesOnFocus = true;

        self.bindViewModel()
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

    //MARK: - Actions -

    @IBAction func onChangePassword(sender: Any?) {
        self.view.endEditing(false)

        self.viewModel.changePassword()
    }

    // MARK: - Notifications -
    func applicationWillEnterForeground(notification: Notification) {
        self.viewModel.restart()
    }

    func keyboardDidShow(notification: Notification) {

        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)

        let bottomInset = self.scrollView.frame.maxY - keyboardFrame.minY
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

// MARK: - UITextFieldDelegate -

extension ChangePasswordViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        switch textField {
        case self.currentPasswordTextField: self.newPasswordTextField.becomeFirstResponder(); return false
        case self.newPasswordTextField: self.self.confirmPasswordTextField.becomeFirstResponder(); return false
        case self.confirmPasswordTextField: self.onChangePassword(sender: nil); return false
        default: break
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
}


// MARK: - Router -
extension ChangePasswordViewController {

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

extension ChangePasswordViewController: ChangePasswordViewModelDelegate {

    func refreshUI() {
        self.changePasswordErrorLabel.text = self.viewModel.changePasswordErrorDescription
        self.changePasswordErrorLabel.isHidden = self.changePasswordErrorLabel.text?.isEmpty ?? true

        self.scrollView.isHidden = self.viewModel.isChangePasswordSucced
        self.changePasswordSuccedLabel.isHidden = !self.viewModel.isChangePasswordSucced
    }

    func errorLabel(for field: MFTextField) -> UILabel? {

        switch field {
        case self.currentPasswordTextField: return self.currentPasswordErrorLabel
        case self.newPasswordTextField: return self.newPasswordErrorLabel
        case self.confirmPasswordTextField: return self.confirmPasswordErrorLabel
        default: return nil
        }
    }

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


    func refreshField(field: ValidatableField, didValidate validationError: ValidationError?) {

        switch field {
        case let textField as MFTextField:
            guard let textFieldErrorLabel = self.errorLabel(for: textField) else { return }
            self.refresh(textField: textField, errorLabel: textFieldErrorLabel, withValidationError: validationError)
        default: break
        }

    }
}
