//
//  ProfileSettingsViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import MaterialTextField
import SwiftValidator

final class ProfileSettingsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var profileSettingsErrorLabel: UILabel!

    @IBOutlet weak var firstnameTextField: MFTextField!
    @IBOutlet weak var firstnameErrorLabel: UILabel!

    @IBOutlet weak var nicknameTextField: MFTextField!
    @IBOutlet weak var nicknameErrorLabel: UILabel!

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

    @IBOutlet weak var phoneTextField: MFTextField!
    @IBOutlet weak var phoneErrorLabel: UILabel!

    @IBOutlet weak var hobbiesTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var hobbiesContainerView: HobbiesContainerView!
    @IBOutlet weak var hobbiesErrorLabel: UILabel!

    @IBOutlet weak var genresTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var genresContainerView: GenresContainerView!
    @IBOutlet weak var genresErrorLabel: UILabel!

    @IBOutlet weak var languageTextFieldSelectionIndicator: UIImageView!
    @IBOutlet weak var languageTextField: LanguageTextField!
    @IBOutlet weak var languageErrorLabel: UILabel!


    // MARK: - Public properties -

    private(set) var viewModel: ProfileSettingsViewModel!
    private(set) var router: FlowRouter!

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: ProfileSettingsViewModel, router: FlowRouter) {
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

        self.firstnameTextField.textColor = self.viewModel.defaultTextColor
        self.firstnameTextField.placeholderAnimatesOnFocus = true
        self.nicknameTextField.textColor = self.viewModel.defaultTextColor
        self.nicknameTextField.placeholderAnimatesOnFocus = true
        self.birthdateTextField.textColor = self.viewModel.defaultTextColor
        self.birthdateTextField.placeholderAnimatesOnFocus = true
        self.birthdateInputView.bind(with: self.birthdateTextField)
        self.birthdateTextField.inputAssistantItem.leadingBarButtonGroups = [];
        self.birthdateTextField.inputAssistantItem.trailingBarButtonGroups = [];
        self.countryTextFieldSelectionIndicator.image = self.countryTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.countryTextField.textColor = self.viewModel.defaultTextColor
        self.countryTextField.placeholderAnimatesOnFocus = true
        self.zipTextField.textColor = self.viewModel.defaultTextColor
        self.zipTextField.placeholderAnimatesOnFocus = true
        self.regionTextFieldSelectionIndicator.image = self.regionTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.regionTextField.textColor = self.viewModel.defaultTextColor
        self.regionTextField.placeholderAnimatesOnFocus = true
        self.cityTextFieldSelectionIndicator.image = self.cityTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.cityTextField.textColor = self.viewModel.defaultTextColor
        self.cityTextField.placeholderAnimatesOnFocus = true
        self.phoneTextField.textColor = self.viewModel.defaultTextColor
        self.phoneTextField.placeholderAnimatesOnFocus = true
        self.hobbiesTextFieldSelectionIndicator.image = self.hobbiesTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.hobbiesContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSelectHobbies(sender:))))
        self.genresTextFieldSelectionIndicator.image = self.genresTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.genresContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSelectGenres(sender:))))
        self.languageTextFieldSelectionIndicator.image = self.languageTextFieldSelectionIndicator.image?.withRenderingMode(.alwaysTemplate)
        self.languageTextField.textColor = self.viewModel.defaultTextColor
        self.languageTextField.placeholderAnimatesOnFocus = true

        self.viewModel.registerFirstNameField(self.firstnameTextField)
        self.viewModel.registerNicknameField(self.nicknameTextField)
        self.viewModel.registerGenderField(self.genderControl)
        self.viewModel.registerBirhDateField(self.birthdateTextField)
        self.viewModel.registerCountryField(self.countryTextField)
        self.viewModel.registerZipField(self.zipTextField)
        self.viewModel.registerRegionField(self.regionTextField)
        self.viewModel.registerCityField(self.cityTextField)
        self.viewModel.registerPhoneField(self.phoneTextField)
        self.viewModel.registerHobbiesField(self.hobbiesContainerView)
        self.viewModel.registerGenresField(self.genresContainerView)
        self.viewModel.registerLanguageField(self.languageTextField)

        self.viewModel.load(with: self)
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { (context) in
            self.hobbiesContainerView.invalidateIntrinsicContentSize()
            self.genresContainerView.invalidateIntrinsicContentSize()
        }
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

    @IBAction func onSelectGenres(sender: UITapGestureRecognizer) {
        self.view.endEditing(false)
        self.viewModel.showGenresSelectableList()
    }

    @IBAction func genresContainerViewValueChanges(sender: GenresContainerView) {
        self.viewModel.validateField(sender)
    }

    @IBAction func onGetLocation(sender: Any?) {

        self.view.endEditing(true)
        self.viewModel.getLocation()
    }

    @IBAction func onSave(sender: Any?) {

        self.view.endEditing(true)
        self.viewModel.save()
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

extension ProfileSettingsViewController: UITextFieldDelegate {

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
        } else if textField === self.languageTextField {
            self.view.endEditing(false)
            self.viewModel.showLanguagesSelectableList()
            return false
        }

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.viewModel.validateField(textField)
    }

//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//
//        guard let nextTextField = self.nextField(for: textField) else { textField.resignFirstResponder(); return true }
//
//        nextTextField.becomeFirstResponder()
//
//        return false
//    }
}

// MARK: - Router -
extension ProfileSettingsViewController {

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

extension ProfileSettingsViewController: ProfileSettingsViewModelDelegate {

    func refreshUI() {
        self.profileSettingsErrorLabel.text = self.viewModel.profileSettingsErrorDescription
        self.profileSettingsErrorLabel.isHidden = self.profileSettingsErrorLabel.text?.isEmpty ?? true

        self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.canSave
    }

    func errorLabel(for field: MFTextField) -> UILabel? {
        if field === self.firstnameTextField { return self.firstnameErrorLabel }
        else if field === self.nicknameTextField { return self.nicknameErrorLabel }
        else if field === self.birthdateTextField { return self.birthdateErrorLabel }
        else if field === self.countryTextField { return self.countryErrorLabel }
        else if field === self.zipTextField { return self.zipErrorLabel }
        else if field === self.regionTextField { return self.regionErrorLabel }
        else if field === self.cityTextField { return self.cityErrorLabel }
        else if field === self.phoneTextField { return self.phoneErrorLabel }
        else if field === self.languageTextField { return self.languageErrorLabel }

        return nil
    }

    func errorLabel(for control: UIControl) -> UILabel? {
        if control === self.genderControl { return self.genderErrorLabel }
        else if control === self.hobbiesContainerView { return self.hobbiesErrorLabel }
        else if control === self.genresContainerView { return self.genresErrorLabel }
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

    func refresh(genresContainerView: GenresContainerView, errorLabel: UILabel, withValidationError validationError: ValidationError?) {

        guard let error = validationError else {
            errorLabel.text = ""
            errorLabel.isHidden = true

            genresContainerView.placeHolderLabel.textColor = self.viewModel.defaultTextColor

            return
        }

        errorLabel.text = error.errorMessage
        errorLabel.isHidden = false

        genresContainerView.placeHolderLabel.textColor = self.viewModel.errorColor
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
        case let textField as MFTextField:
            guard let textFieldErrorLabel = self.errorLabel(for: textField) else { return }
            self.refresh(textField: textField, errorLabel: textFieldErrorLabel, withValidationError: validationError)

        case let hobbiesContainerView as HobbiesContainerView:
            guard let controlErrorLabel = self.errorLabel(for: hobbiesContainerView) else { return }
            self.refresh(hobbiesContainerView: hobbiesContainerView, errorLabel: controlErrorLabel, withValidationError: validationError)

        case let genresContainerView as GenresContainerView:
            guard let controlErrorLabel = self.errorLabel(for: genresContainerView) else { return }
            self.refresh(genresContainerView: genresContainerView, errorLabel: controlErrorLabel, withValidationError: validationError)

        case let control as UIControl:
            guard let controlErrorLabel = self.errorLabel(for: control) else { return }
            self.refresh(control: control, errorLabel: controlErrorLabel, withValidationError: validationError)

        default: break
        }
    }

    func refreshFirstNameField(with name: String?) { self.firstnameTextField.text = name }
    func refreshNickNameField(with name: String?) { self.nicknameTextField.text = name }
    func refreshGenderField(with gender: Gender?) { self.genderControl.gender = gender }
    func refreshBirthDateField(with date: Date?) { self.birthdateTextField.date = date }

    func refreshCountryField(with country: Country?) { self.countryTextField.country = country }
    func refreshZipField(with zip: String?) { self.zipTextField.text = zip }
    func refreshRegionField(with region: Region?) { self.regionTextField.region = region }
    func refreshCityField(with city: City?) { self.cityTextField.city = city }
    func refreshPhoneField(with phone: String?) { self.phoneTextField.text = phone }

    func refreshHobbiesField(with hobbies: [Hobby]?) { self.hobbiesContainerView.hobbies = hobbies }
    func refreshGenresField(with genres: [Genre]?) { self.genresContainerView.genres = genres }
    func refreshLanguageField(with language: Language?) { self.languageTextField.language = language }
}
