//
//  SignUpViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator
import NSStringMask

class SignUpContentView: UIView {

}

final class SignUpViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var signUpSuccedLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: SignUpContentView!

    @IBOutlet weak var signUpErrorLabel: UILabel!

    @IBOutlet weak var emailTextField: MFTextField!
    @IBOutlet weak var emailErrorLabel: UILabel!

    @IBOutlet weak var passwordTextField: MFTextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    @IBOutlet weak var passwordConfirmationTextField: MFTextField!
    @IBOutlet weak var passwordConfirmationErrorLabel: UILabel!

    @IBOutlet weak var nicknameTextField: MFTextField!
    @IBOutlet weak var nicknameErrorLabel: UILabel!

    @IBOutlet weak var firstnameTextField: MFTextField!
    @IBOutlet weak var firstnameErrorLabel: UILabel!

    @IBOutlet weak var genderControl: GenderSegmentedControl!
    @IBOutlet weak var genderErrorLabel: UILabel!

    @IBOutlet weak var birthdateTextField: DateTextField!
    @IBOutlet weak var birthdateErrorLabel: UILabel!
    @IBOutlet weak var birthdateInputView: DatePickerInputView!

    @IBOutlet weak var countryTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var countryTextField: CountryTextField!
    @IBOutlet weak var countryErrorLabel: UILabel!

    @IBOutlet weak var zipTextField: MFTextField!
    @IBOutlet weak var zipErrorLabel: UILabel!

    @IBOutlet weak var regionTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var regionTextField: RegionTextField!
    @IBOutlet weak var regionErrorLabel: UILabel!

    @IBOutlet weak var cityTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var cityTextField: CityTextField!
    @IBOutlet weak var cityErrorLabel: UILabel!

    @IBOutlet weak var phoneTextField: MaskedTextField!
    @IBOutlet weak var phoneErrorLabel: UILabel!

    @IBOutlet weak var hobbiesTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var hobbiesContainerView: HobbiesContainerView!
    @IBOutlet weak var hobbiesErrorLabel: UILabel!

    @IBOutlet weak var howHearTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var howHearTextField: HowHearTextField!
    @IBOutlet weak var howHearErrorLabel: UILabel!

    // MARK: - Public properties -

    private(set) var viewModel: SignUpViewModel!
    private(set) var router: FlowRouter!

    private(set) var fields = [UITextField]()

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: SignUpViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded {

            self.emailTextField.text = nil
            self.passwordTextField.text = nil
            self.passwordConfirmationTextField.text = nil
            self.nicknameTextField.text = nil
            self.firstnameTextField.text = nil
            self.genderControl.selectedSegmentIndex = -1
            self.birthdateTextField.date = nil
            self.birthdateInputView.datePicker.date = Date()
            self.countryTextField.country = nil
            self.zipTextField.text = nil
            self.regionTextField.region = nil
            self.cityTextField.city = nil
            self.phoneTextField.text = nil
            self.hobbiesContainerView.hobbies = nil
            self.howHearTextField.howHear = nil

            self.scrollView.setContentOffset(CGPoint.zero, animated: false)

            self.bindViewModel()
        }
    }

    func bindViewModel() {
        viewModel.load(with: self)

        self.viewModel.registerEmailField(self.emailTextField)
        self.viewModel.registerPasswordField(self.passwordTextField)
        self.viewModel.registerPasswordConfirmationField(self.passwordConfirmationTextField, passwordField: self.passwordTextField)
        self.viewModel.registerNicknameField(self.nicknameTextField)
        self.viewModel.registerFirstNameField(self.firstnameTextField)
        self.viewModel.registerGenderField(self.genderControl)
        self.viewModel.registerBirhDateField(self.birthdateTextField)
        self.viewModel.registerCountryField(self.countryTextField)
        self.viewModel.registerZipField(self.zipTextField)
        self.viewModel.registerRegionField(self.regionTextField)
        self.viewModel.registerCityField(self.cityTextField)
        self.viewModel.registerPhoneField(MaskedValidatebleFieldWrapper(with: self.phoneTextField))
        self.viewModel.registerHobbiesField(self.hobbiesContainerView)
        self.viewModel.registerHowHearField(self.howHearTextField)
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

        self.hobbiesContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSelectHobbies(sender:))))

        self.emailTextField.textColor = self.viewModel.defaultTextColor
        self.emailTextField.placeholderAnimatesOnFocus = true;
        self.passwordTextField.textColor = self.viewModel.defaultTextColor
        self.passwordTextField.placeholderAnimatesOnFocus = true
        self.passwordConfirmationTextField.textColor = self.viewModel.defaultTextColor
        self.passwordConfirmationTextField.placeholderAnimatesOnFocus = true
        self.nicknameTextField.textColor = self.viewModel.defaultTextColor
        self.nicknameTextField.placeholderAnimatesOnFocus = true
        self.firstnameTextField.textColor = self.viewModel.defaultTextColor
        self.firstnameTextField.placeholderAnimatesOnFocus = true
        self.birthdateTextField.textColor = self.viewModel.defaultTextColor
        self.birthdateTextField.placeholderAnimatesOnFocus = true
        self.countryTextField.textColor = self.viewModel.defaultTextColor
        self.countryTextField.placeholderAnimatesOnFocus = true
        self.zipTextField.textColor = self.viewModel.defaultTextColor
        self.zipTextField.placeholderAnimatesOnFocus = true
        self.regionTextField.textColor = self.viewModel.defaultTextColor
        self.regionTextField.placeholderAnimatesOnFocus = true
        self.cityTextField.textColor = self.viewModel.defaultTextColor
        self.cityTextField.placeholderAnimatesOnFocus = true
        self.phoneTextField.textColor = self.viewModel.defaultTextColor
        self.phoneTextField.placeholderAnimatesOnFocus = true
        self.phoneTextField.stringMask = NSStringMask(pattern: "\\(([1-9]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]{1})\\) (\\d{3})-(\\d{4})", placeholder: "_")
        self.howHearTextField.textColor = self.viewModel.defaultTextColor
        self.howHearTextField.placeholderAnimatesOnFocus = true

        self.birthdateInputView.bind(with: self.birthdateTextField)
        self.birthdateTextField.inputAssistantItem.leadingBarButtonGroups = [];
        self.birthdateTextField.inputAssistantItem.trailingBarButtonGroups = [];

        self.countryTextFieldSelectionIndicator.image = self.countryTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.regionTextFieldSelectionIndicator.image = self.regionTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.cityTextFieldSelectionIndicator.image = self.cityTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.hobbiesTextFieldSelectionIndicator.image = self.hobbiesTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.howHearTextFieldSelectionIndicator.image = self.howHearTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)

        self.fields = [
            self.emailTextField,
            self.passwordTextField,
            self.passwordConfirmationTextField,
            self.nicknameTextField,
            self.firstnameTextField,
            self.birthdateTextField,
            self.zipTextField,
            self.phoneTextField,
        ]

        self.bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardDidShow(notification: notification)
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { (context) in
            self.hobbiesContainerView.setNeedsLayout()
        }
    }

    func nextField(for textField: UITextField) -> UITextField? {

        guard let textFieldIndex = self.fields.index(of: textField), self.fields.count > textFieldIndex + 1 else { return nil }

        return self.fields[textFieldIndex + 1]
    }

    // MARK: - Actions -

    @IBAction func genderSegmentedControlChanged(sender: GenderSegmentedControl) {
        self.viewModel.validateField(sender)
    }

    @IBAction func onSelectHobbies(sender: UITapGestureRecognizer) {
        self.view.endEditing(false)
        self.viewModel.showHobbiesSelectableList()
    }

    @IBAction func hobbiesContainerViewValueChanges(sender: HobbiesContainerView) {
        self.viewModel.validateField(sender)
    }

    @IBAction func onSignUp(sender: Any?) {

        self.view.endEditing(true)
        self.viewModel.signUp()

        self.scrollView.setContentOffset(CGPoint.zero, animated: true)
    }

    @IBAction func onGetLocation(sender: Any?) {
        self.view.endEditing(true)
        self.viewModel.getLocation()
    }

    // MARK: - UITextFieldDelegate -

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === self.countryTextField {
            self.view.endEditing(false)
            self.viewModel.showContriesSelectableList()
            return false
        } else if textField === self.regionTextField {
            self.view.endEditing(false)
            self.viewModel.showRegionsSelectableList()
            return false
        } else if textField === self.cityTextField {
            self.view.endEditing(false)
            self.viewModel.showCitiesSelectableList()
            return false
        } else if textField === self.howHearTextField {
            self.view.endEditing(false)
            self.viewModel.showHowHearSelectableList()
            return false
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(textField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        guard let nextTextField = self.nextField(for: textField) else { textField.resignFirstResponder(); return true }

        nextTextField.becomeFirstResponder()

        return false
    }

    @IBAction func textFieldEditingChange(textField: UITextField) {

        let textFieldFrame = self.contentView.convert(textField.frame, to: self.scrollView)
        let scrollViewBounds = self.scrollView.bounds.inset(by: self.scrollView.contentInset)

        if scrollViewBounds.contains(textFieldFrame) == false {
            scrollView.scrollRectToVisible(textFieldFrame, animated: true)
        }
    }

    // MARK: - Notifications -

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
extension SignUpViewController {

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

extension SignUpViewController: SignUpViewModelDelegate {

    func refreshUI() {
        self.signUpErrorLabel.text = self.viewModel.signUpErrorDescription
        self.signUpErrorLabel.isHidden = self.signUpErrorLabel.text?.isEmpty ?? true

        self.scrollView.isHidden = self.viewModel.isSignUpSucced
        self.signUpSuccedLabel.isHidden = !self.viewModel.isSignUpSucced
    }

    func errorLabel(for field: MFTextField) -> UILabel? {
        if field === self.emailTextField { return self.emailErrorLabel }
        else if field === self.passwordTextField { return self.passwordErrorLabel }
        else if field === self.passwordConfirmationTextField { return self.passwordConfirmationErrorLabel }
        else if field === self.nicknameTextField { return self.nicknameErrorLabel }
        else if field === self.firstnameTextField { return self.firstnameErrorLabel }
        else if field === self.birthdateTextField { return self.birthdateErrorLabel }
        else if field === self.countryTextField { return self.countryErrorLabel }
        else if field === self.zipTextField { return self.zipErrorLabel }
        else if field === self.regionTextField { return self.regionErrorLabel }
        else if field === self.cityTextField { return self.cityErrorLabel }
        else if field === self.phoneTextField { return self.phoneErrorLabel }
        else if field === self.howHearTextField { return self.howHearErrorLabel }

        return nil
    }

    func errorLabel(for control: UIControl) -> UILabel? {
        if control === self.genderControl { return self.genderErrorLabel }
        else if control === self.hobbiesContainerView { return self.hobbiesErrorLabel }
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

    func refresh(hobbiesContainerView: HobbiesContainerView, errorLabel: UILabel, withValidationError validationError: ValidationError?) {

        guard let error = validationError else {
            errorLabel.text = ""
            errorLabel.isHidden = true

            hobbiesContainerView.placeHolderLabel.textColor = self.viewModel.defaultTextColor

            return
        }

        errorLabel.text = error.errorMessage
        errorLabel.isHidden = false

        hobbiesContainerView.placeHolderLabel.textColor = self.viewModel.errorColor
    }

    func refresh(control: UIControl, errorLabel: UILabel, withValidationError validationError: ValidationError?) {
        guard let error = validationError else {
            errorLabel.text = ""
            errorLabel.isHidden = true

            return
        }

        errorLabel.text = error.errorMessage
        errorLabel.isHidden = false
    }

    func refreshField(field: ValidatableField, didValidate validationError: ValidationError?) {

        switch field {
        case let textFieldWrapper as ValidatebleFieldWrapper:
            guard let textField = textFieldWrapper.textField as? MFTextField, let textFieldErrorLabel = self.errorLabel(for: textField) else { return }
            self.refresh(textField: textField, errorLabel: textFieldErrorLabel, withValidationError: validationError)

        case let textField as MFTextField:
            guard let textFieldErrorLabel = self.errorLabel(for: textField) else { return }
            self.refresh(textField: textField, errorLabel: textFieldErrorLabel, withValidationError: validationError)

        case let hobbiesContainerView as HobbiesContainerView:
            guard let controlErrorLabel = self.errorLabel(for: hobbiesContainerView) else { return }
            self.refresh(hobbiesContainerView: hobbiesContainerView, errorLabel: controlErrorLabel, withValidationError: validationError)

        case let control as UIControl:
            guard let controlErrorLabel = self.errorLabel(for: control) else { return }
            self.refresh(control: control, errorLabel: controlErrorLabel, withValidationError: validationError)

        default: break
        }
    }

    func refreshCountryField(with country: Country?) {
        self.countryTextField.country = country
    }

    func refreshZipField(with zip: String?) {
        self.zipTextField.text = zip ?? ""
    }

    func refreshRegionField(with region: Region?) {
        self.regionTextField.region = region
    }

    func refreshCityField(with city: City?) {
        self.cityTextField.city = city
    }

    func refreshHobbiesField(with hobbies: [Hobby]) {
        self.hobbiesContainerView.hobbies = hobbies
    }

    func refreshHowHearField(with howHear: HowHear?) {
        self.howHearTextField.howHear = howHear
    }
}

// MARK: - AuthorizationChildViewController -
extension SignUpViewController: AuthorizationChildViewController {
    var authorizationType: AuthorizationType { return .signUp }
}
