//
//  SignUpControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator
import Alamofire

final class SignUpControllerViewModel: SignUpViewModel {

    // MARK: - Public properties

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041702, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: SignUpViewModelDelegate?
    private(set) weak var router: SignUpRouter?
    private(set) weak var restApiService: RestApiService?

    var isSignUpSucced: Bool { return self.registeredUserProfile != nil }

    private(set) var countries: [Country]
    var selectedCountry: Country? { return countryField?.country }

    private(set) var regions: [Region]
    var selectedRegion: Region? { return regionField?.region }

    private(set) var cities: [City]
    var selectedCity: City? { return cityField?.city }

    private(set) var hobbies: [Hobby]
    var selectedHobbies: [Hobby]? { return hobbiesField?.hobbies }

    private(set) var howHearList: [HowHear]
    var selectedHowHear: HowHear? { return howHearField?.howHear }

    private let validator: Validator

    private(set) var signUpErrorDescription: String?

    private var registeredUserProfile: UserProfile?

    private var emailField: ValidatableField?
    private var passwordField: ValidatableField?
    private var passwordConfirmationField: ValidatableField?
    private var nicknameField: ValidatableField?
    private var firstnameField: ValidatableField?
    private var genderField: GenderValidatableField?
    private var birthdateField: DateValidatableField?
    private var countryField: CountryValidatableField?
    private var zipField: ValidatableField?
    private var regionField: RegionValidatableField?
    private var cityField: CityValidatableField?
    private var phoneField: ValidatableField?
    private var hobbiesField: HobbiesValidatableField?
    private var howHearField: HowHearValidatableField?

    // MARK: - Lifecycle -

    init(router: SignUpRouter, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService

        self.countries = [Country]()
        self.regions = [Region]()
        self.cities = [City]()
        self.hobbies = [Hobby]()
        self.howHearList = [HowHear]()

        self.validator = Validator()
    }

    func load(with delegate: SignUpViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
            self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })


        self.reloadContries { [weak self] (countriesResult) in
            switch countriesResult {
            case .success(let countries):
                guard let unitedStatesCountry = countries.filter( { return $0.code == "US" } ).first else { return }
                self?.set(country: unitedStatesCountry)
            default: break
            }
        }

        self.delegate?.refreshUI()
    }

    func reloadConfig(completion: @escaping (Result<Config>) -> Void) {

        self.restApiService?.config(completion: { [weak self] (configResult) in
            switch configResult {
            case .success(let config):
                self?.hobbies = config.hobbies
                self?.howHearList = config.howHearList

                if let selectedHobbies = self?.selectedHobbies, selectedHobbies.count > 0 {
                    let filteredSelectedHobbies = selectedHobbies.filter( { return config.hobbies.contains($0) })
                    self?.delegate?.refreshHobbiesField(with: filteredSelectedHobbies)
                }

                if let selectedHowHear = self?.selectedHowHear, config.howHearList.contains(selectedHowHear) == false {
                    self?.delegate?.refreshHowHearField(with: nil)
                }

            default: break
            }

            completion(configResult)
        })
    }

    func registerEmailField(_ emailField: ValidatableField) {

        let emailRules: [Rule] = [RequiredRule(message: "The email field is required."),
                                  EmailRule(message: "The email is wrong")]
        self.validator.registerField(emailField, rules: emailRules)

        self.emailField = emailField

        if emailField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: emailField, didValidate: nil)
        } else {
            self.validator.validateField(emailField) { (validationError) in }
        }
    }

    func registerPasswordField(_ passwordField: ValidatableField) {

        let passwordRules: [Rule] = [RequiredRule(message: "The password field is required."),
                                     MinLengthRule(length: 6, message: "The password must be at least %ld characters")]
        self.validator.registerField(passwordField, rules: passwordRules)

        self.passwordField = passwordField

        self.delegate?.refreshField(field: passwordField, didValidate: nil)
    }

    func registerPasswordConfirmationField(_ passwordConfirmationField: ValidatableField, passwordField: ValidatableField) {
        let passwordConfirmationRules: [Rule] = [RequiredRule(message: "The password confirmation field is required."),
                                                 ConfirmationRule(confirmField: passwordField, message: "Your password and confirmation password do not match.")]

        self.validator.registerField(passwordConfirmationField, rules: passwordConfirmationRules)

        self.passwordConfirmationField = passwordConfirmationField

        self.delegate?.refreshField(field: passwordConfirmationField, didValidate: nil)
    }

    func registerNicknameField(_ nicknameField: ValidatableField) {
        let nicknameRules: [Rule] = [RequiredRule(message: "The nick name field is required.")]
        self.validator.registerField(nicknameField, rules: nicknameRules)

        self.nicknameField = nicknameField

        if nicknameField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: nicknameField, didValidate: nil)
        } else {
            self.validator.validateField(nicknameField) { (validationError) in }
        }
    }

    func registerFirstnameField(_ firstnameField: ValidatableField) {
        let firstnameRules: [Rule] = [RequiredRule(message: "The first name field is required.")]
        self.validator.registerField(firstnameField, rules: firstnameRules)

        self.firstnameField = firstnameField

        if firstnameField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: firstnameField, didValidate: nil)
        } else {
            self.validator.validateField(firstnameField) { (validationError) in }
        }
    }

    func registerGenderField(_ genderField: GenderValidatableField) {
        let genderRules: [Rule] = [RequiredRule(message: "The gender field is required.")]
        self.validator.registerField(genderField, rules: genderRules)

        self.genderField = genderField

        self.delegate?.refreshField(field: genderField, didValidate: nil)
    }

    func registerBirhdateField(_ birthdateField: DateValidatableField) {
        let birthdateRules: [Rule] = [RequiredRule(message: "The birth date field is required.")]

        self.validator.registerField(birthdateField, rules: birthdateRules)

        self.birthdateField = birthdateField

        if birthdateField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: birthdateField, didValidate: nil)
        } else {
            self.validator.validateField(birthdateField) { (validationError) in }
        }
    }

    func registerCountryField(_ countryField: CountryValidatableField) {
        let countryRules: [Rule] = [RequiredRule(message: "The country field is required")]

        self.validator.registerField(countryField, rules: countryRules)

        self.countryField = countryField

        if countryField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: countryField, didValidate: nil)
        } else {
            self.validator.validateField(countryField) { (validationError) in }
        }
    }

    func registerZipField(_ zipField: ValidatableField) {
        let zipRules: [Rule] = [RequiredRule(message: "The zip field is required"),
                                MaxLengthRule(length: 15, message: "The zip field must be at most %ld characters long")]

        self.validator.registerField(zipField, rules: zipRules)

        self.zipField = zipField

        if zipField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: zipField, didValidate: nil)
        } else {
            self.validator.validateField(zipField) { (validationError) in }
        }
    }

    func registerRegionField(_ regionField: RegionValidatableField) {
        let regionRules: [Rule] = [RequiredRule(message: "The state field is required.")]

        self.validator.registerField(regionField, rules: regionRules)

        self.regionField = regionField

        if regionField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: regionField, didValidate: nil)
        } else {
            self.validator.validateField(regionField) { (validationError) in }
        }
    }

    func registerCityField(_ cityField: CityValidatableField) {
        let cityRules: [Rule] = [RequiredRule(message: "The city field is required.")]

        self.validator.registerField(cityField, rules: cityRules )

        self.cityField = cityField

        if cityField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: cityField, didValidate: nil)
        } else {
            self.validator.validateField(cityField) { (validationError) in }
        }
    }

    func registerPhoneField(_ phoneField: ValidatableField) {
        let phoneRules: [Rule] = [/*PhoneNumberRule(message: "The phone is wrong")*/]

        self.validator.registerField(phoneField, rules: phoneRules )

        self.phoneField = phoneField

        if phoneField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: phoneField, didValidate: nil)
        } else {
            self.validator.validateField(phoneField) { (validationError) in }
        }
    }

    func registerHobbiesField(_ hobbiesField: HobbiesValidatableField) {
        let hobbiesRules: [Rule] = [RequiredRule(message: "The hobbies field is required.")]

        self.validator.registerField(hobbiesField, rules: hobbiesRules)

        self.hobbiesField = hobbiesField

        if hobbiesField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: hobbiesField, didValidate: nil)
        } else {
            self.validator.validateField(hobbiesField) { (validationError) in }
        }
    }

    func registerHowHearField(_ howHearField: HowHearValidatableField) {
        let howHearRules: [Rule] = [RequiredRule(message: "The how hear field is required.")]

        self.validator.registerField(howHearField, rules: howHearRules)

        self.howHearField = howHearField

        if howHearField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: howHearField, didValidate: nil)
        } else {
            self.validator.validateField(howHearField) { (validationError) in }
        }
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }
    }

    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "email": return self.emailField
        case "password": return self.passwordField
        case "password_confirmation": return self.passwordConfirmationField
        case "nick_name": return self.nicknameField
        case "real_name": return self.firstnameField
        case "gender": return self.genderField
        case "birth_date": return self.birthdateField
        case "hobbies": return self.hobbiesField
        case "how_hear": return self.howHearField
        default: break
        }

        return nil
    }

    func set(country: Country) {

        let isNeedReloadRegions = country != self.countryField?.country
        self.delegate?.refreshCountryField(with: country)
        self.validateField(self.countryField)

        if isNeedReloadRegions {
            self.regions.removeAll()
            self.cities.removeAll()

            let region = self.regionField?.region
            self.delegate?.refreshRegionField(with: nil)
            if region != nil { self.validateField(self.regionField) }

            let city = self.cityField?.city
            self.delegate?.refreshCityField(with: nil)
            if city != nil { self.validateField(self.cityField) }

            self.reloadRegions { (regionsResult) in }
        }
    }

    func set(region: Region) {

        let isNeedReloadCities = region != self.regionField?.region
        self.delegate?.refreshRegionField(with: region)
        self.validateField(self.regionField)

        if isNeedReloadCities {
            self.cities.removeAll()

            let city = self.cityField?.city
            self.delegate?.refreshCityField(with: nil)
            if city != nil { self.validateField(self.cityField) }

            self.reloadCities { (citiesResult) in }
        }
    }

    func set(city: City) {
        self.delegate?.refreshCityField(with: city)
        self.validateField(self.cityField)
    }

    func set(hobbies: [Hobby]) {
        self.delegate?.refreshHobbiesField(with: hobbies)
        self.validateField(self.hobbiesField)
    }

    func set(howHear: HowHear) {
        self.delegate?.refreshHowHearField(with: howHear)
        self.validateField(self.howHearField)
    }

    func getLocation() {

        guard let countryField = self.countryField, let zipField = self.zipField else { return }

        var countryFieldValidationError: ValidationError?
        var zipFieldValidationError: ValidationError?

        self.validator.validateField(countryField) { (validationError) in countryFieldValidationError = validationError }
        self.validator.validateField(zipField) { (validationError) in zipFieldValidationError = validationError }

        guard countryFieldValidationError == nil && zipFieldValidationError == nil,
            let country = countryField.country else { return }

        self.restApiService?.location(for: country, zip: zipField.validationText, completion: { [weak self] (detailedLocationResult) in

            guard let `self` = self else { return }
            guard let countryField = self.countryField, let zipField = self.zipField,
                let regionField = self.regionField, let cityField = self.cityField else { return }

            switch detailedLocationResult {
            case .success(let detailedLocation):

                self.regions = detailedLocation.regions
                self.cities = detailedLocation.cities

                self.delegate?.refreshCountryField(with: detailedLocation.location.country)
                self.validator.validateField(countryField, callback: { (validationError) in })
                self.delegate?.refreshZipField(with: detailedLocation.location.zip)
                self.validator.validateField(zipField, callback: { (validationError) in })
                self.delegate?.refreshRegionField(with: detailedLocation.location.region)
                self.validator.validateField(regionField, callback: { (validationError) in })
                self.delegate?.refreshCityField(with: detailedLocation.location.city)
                self.validator.validateField(cityField, callback: { (validationError) in })

            case .failure(let error):
                guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                    self.delegate?.show(error: error)
                    return
                }

                switch appErrorGroup {
                case RestApiServiceError.serverError( let errorDescription, _ ):

                    let validationError = ValidationError(field: regionField, errorLabel: nil, error: errorDescription)
                    self.delegate?.refreshField(field: regionField, didValidate: validationError)

                default:
                    self.delegate?.show(error: error)
                }
            }
        })
    }

    func signUp() {

        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText,
                let password = self.passwordField?.validationText,
                let passwordConfirmation = self.passwordConfirmationField?.validationText,
                let nickName = self.nicknameField?.validationText,
                let firstName = self.firstnameField?.validationText,
                let birhDate = self.birthdateField?.date,
                let gender = self.genderField?.gender,
                let country = self.countryField?.country,
                let region = self.regionField?.region,
                let city = self.cityField?.city,
                let zip = self.zipField?.validationText,
                let phone = self.phoneField?.validationText,
                let hobbies = self.hobbiesField?.hobbies,
                let howHear = self.howHearField?.howHear else { return }

            let location = Location(country: country, region: region, city: city, zip: zip)
            let registrationPayload = RestApiFanUserRegistrationRequestPayload(email: email,
                                                                               password: password,
                                                                               passwordConfirmation: passwordConfirmation,
                                                                               nickName: nickName,
                                                                               realName: firstName,
                                                                               birthDate: birhDate,
                                                                               gender: gender,
                                                                               location: location,
                                                                               phone: phone,
                                                                               hobbies: hobbies,
                                                                               howHear: howHear)

            self.restApiService?.fanUser(register: registrationPayload, completion: { [weak self] (registrationResult) in

                switch (registrationResult) {
                case .success(let userProfile):
                    self?.registeredUserProfile = userProfile
                    self?.delegate?.refreshUI()
                    

                case .failure(let error):
                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                        self?.delegate?.show(error: error)
                        return
                    }

                    switch appErrorGroup {
                    case RestApiServiceError.serverError( let errorDescription, let errors):
                        self?.signUpErrorDescription = errorDescription
                        for (key, errorStrings) in errors {
                            guard let validatebleField = self?.validatebleField(for: key), let validatebleFieldErrorString = errorStrings.first else { continue }

                            let validationError = ValidationError(field: validatebleField, errorLabel: nil, error: validatebleFieldErrorString)
                            self?.delegate?.refreshField(field: validatebleField, didValidate: validationError)
                        }

                    default:
                        self?.delegate?.show(error: error)
                    }

                    self?.delegate?.refreshUI()
                }

            })
        }
    }
}

// MARK: - CountriesDataProvider -

extension SignUpControllerViewModel {

    func reloadContries(completion: @escaping (Result<[Country]>) -> Void) {
        self.restApiService?.countries(completion: { [weak self] (contriesResult) in
            switch contriesResult {
            case .success(let countries):
                self?.countries = countries
                if let selectedCountry = self?.selectedCountry, countries.contains(selectedCountry) == false {
                    self?.delegate?.refreshCountryField(with: nil)
                }
                completion(.success(countries))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func reloadRegions(completion: @escaping (Result<[Region]>) -> Void) {
        guard let country = self.countryField?.country else { completion(.success([])); return }

        self.restApiService?.regions(for: country, completion: { [weak self] (regionsResult) in
            switch regionsResult {
            case .success(let regions):
                self?.regions = regions
                if let selectedRegion = self?.selectedRegion, regions.contains(selectedRegion) == false {
                    self?.delegate?.refreshRegionField(with: nil)
                }
                completion(.success(regions))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func reloadCities(completion: @escaping (Result<[City]>) -> Void) {
        guard let region = self.regionField?.region else { completion(.success([])); return }

        self.restApiService?.cities(for: region, completion: { [weak self] (citiesResult) in
            switch citiesResult {
            case .success(let cities):
                self?.cities = cities
                if let selectedCity = self?.selectedCity, cities.contains(selectedCity) == false {
                    self?.delegate?.refreshCityField(with: nil)
                }
                completion(.success(cities))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func reloadHobbies(completion: @escaping (Result<[Hobby]>) -> Void) {
        self.reloadConfig { (configResult) in
            switch configResult {
            case .success(let config):
                completion(.success(config.hobbies))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func reloadHowHearList(completion: @escaping (Result<[HowHear]>) -> Void) {
        self.reloadConfig { (configResult) in
            switch configResult {
            case .success(let config):
                completion(.success(config.howHearList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
