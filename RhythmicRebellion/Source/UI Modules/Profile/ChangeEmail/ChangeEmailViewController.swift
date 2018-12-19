//
//  ChangeEmailViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator

final class ChangeEmailViewController: UIViewController, ScrollableContentViewController {

    @IBOutlet weak var changeEmailSuccedLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var changeEmailErrorLabel: UILabel!
    @IBOutlet weak var newEmailTextField: MFTextField!
    @IBOutlet weak var newEmailErrorLabel: UILabel!
    @IBOutlet weak var currentPasswordTextField: MFTextField!
    @IBOutlet weak var currentPasswordErrorLabel: UILabel!


    // MARK: - Public properties -

    private(set) var viewModel: ChangeEmailViewModel!
    private(set) var router: FlowRouter!

    internal var applicationWillEnterForegroundObserver: NSObjectProtocol?
    internal var keyboardWillShowObserver: NSObjectProtocol?
    internal var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: ChangeEmailViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded {

            self.currentPasswordTextField.text = ""

            self.bindViewModel()
        }
    }

    func bindViewModel() {
        viewModel.load(with: self)

        viewModel.registerNewEmailField(self.newEmailTextField)
        viewModel.registerCurrentPasswordField(self.currentPasswordTextField)
    }


    // MARK: - Lifecycle -

    deinit {

        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }

        self.stopObserveKeyboard()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.newEmailTextField.textColor = self.viewModel.defaultTextColor
        self.newEmailTextField.placeholderAnimatesOnFocus = true;
        self.currentPasswordTextField.textColor = self.viewModel.defaultTextColor
        self.currentPasswordTextField.placeholderAnimatesOnFocus = true;

        self.bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in

            self.viewModel.restart()
        }

        self.startObserveKeyboard()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let applicationWillEnterForegroundObserver = self.applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
            self.applicationWillEnterForegroundObserver = nil
        }

        self.stopObserveKeyboard()
    }

    // MARK: - Actions -

    @IBAction func onChangePassword(sender: Any?) {
        self.view.endEditing(false)

        self.viewModel.changeEmail()
    }

}

// MARK: - UITextFieldDelegate -

extension ChangeEmailViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        switch textField {
        case self.newEmailTextField: self.currentPasswordTextField.becomeFirstResponder(); return false
        case self.currentPasswordTextField: self.onChangePassword(sender: self); return false

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
extension ChangeEmailViewController {

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

extension ChangeEmailViewController: ChangeEmailViewModelDelegate {

    func refreshUI() {
        self.changeEmailErrorLabel.text = self.viewModel.changeEmailErrorDescription
        self.changeEmailErrorLabel.isHidden = self.changeEmailErrorLabel.text?.isEmpty ?? true

        self.scrollView.isHidden = self.viewModel.isChangeEmailSucced
        self.changeEmailSuccedLabel.isHidden = !self.viewModel.isChangeEmailSucced
    }

    func errorLabel(for field: MFTextField) -> UILabel? {

        switch field {
        case self.newEmailTextField: return self.newEmailErrorLabel
        case self.currentPasswordTextField: return self.currentPasswordErrorLabel
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
