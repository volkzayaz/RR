//
//  RestorePasswordViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator

final class RestorePasswordViewController: UIViewController {

    @IBOutlet weak var restorePasswordSuccedLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var restorePasswordErrorLabel: UILabel!
    @IBOutlet weak var emailTextField: MFTextField!
    @IBOutlet weak var emailErrorLabel: UILabel!

    // MARK: - Public properties -

    private(set) var viewModel: RestorePasswordViewModel!
    private(set) var router: FlowRouter!

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: RestorePasswordViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    deinit {
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

        self.emailTextField.textColor = self.viewModel.defaultTextColor
        self.emailTextField.placeholderAnimatesOnFocus = true;

        viewModel.load(with: self)

        self.viewModel.registerEmailField(self.emailTextField)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidShow, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardDidShow(notification: notification)
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardWillHide(notification: notification)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }

    // MARK: - Actions -

    @IBAction func onRestore(sender: Any?) {

        self.view.endEditing(false)
        self.viewModel.restorePassword()
    }

    // MARK: - Notifications -
    func keyboardDidShow(notification: Notification) {
        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
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


// MARK: - UITextFieldDelegate -
extension RestorePasswordViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField === self.emailTextField {
            self.onRestore(sender: self)
        }

        return true
    }
}


// MARK: - Router -
extension RestorePasswordViewController {

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

extension RestorePasswordViewController: RestorePasswordViewModelDelegate {

    func refreshUI() {
        self.restorePasswordErrorLabel.text = self.viewModel.restorePasswordErrorDescription
        self.restorePasswordErrorLabel.isHidden = self.restorePasswordErrorLabel.text?.isEmpty ?? true

        self.scrollView.isHidden = self.viewModel.isRestorePasswordSucced
        self.restorePasswordSuccedLabel.isHidden = !self.viewModel.isRestorePasswordSucced
    }

    func errorLabel(for field: MFTextField) -> UILabel? {
        if field === self.emailTextField { return self.emailErrorLabel }

        return nil
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

    func refreshEmailField(with email: String?) {
        self.emailTextField.text = email
    }
}
