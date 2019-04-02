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

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    var isSignUpSucced: Bool { return self.registeredUserProfile != nil }
    
    // MARK: - Private properties -

    private(set) weak var delegate: SignUpViewModelDelegate?
    private(set) weak var router: SignUpRouter?
    private(set) weak var application: Application?
    private(set) weak var restApiService: RestApiService?

    private(set) var countries: [Country]
    private(set) var regions: [Region]
    private(set) var cities: [City]
    var howHearList: [HowHear] { return self.application?.config?.howHearList ?? [] }
    private let validator: Validator

    private(set) var signUpErrorDescription: String?

    private var registeredUserProfile: UserProfile?

    private var emailField: ValidatableField?
    private var passwordField: ValidatableField?
    private var passwordConfirmationField: ValidatableField?
    private var nicknameField: ValidatableField?
    private var firstNameField: ValidatableField?
    private var genderField: GenderValidatableField?
    private var birthDateField: DateValidatableField?
    private var countryField: CountryValidatableField?
    private var zipField: ValidatableField?
    private var regionField: RegionValidatableField?
    private var cityField: CityValidatableField?
    private var phoneField: MaskedValidatebleField?
    private var hobbiesField: HobbiesValidatableField?
    private var howHearField: HowHearValidatableField?

    // MARK: - Lifecycle -

    init(router: SignUpRouter, application: Application, restApiService: RestApiService) {
        self.router = router
        self.restApiService = restApiService
        self.application = application

        self.countries = [Country]()
        self.regions = [Region]()
        self.cities = [City]()

        self.validator = Validator()
    }

    func load(with delegate: SignUpViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
            self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })


        if self.application?.config == nil {
            self.loadConfig()
        }

        self.reloadCountries { [weak self] (countriesResult) in
            switch countriesResult {
            case .success(let countries):
                guard let unitedStatesCountry = countries.filter( { return $0.code == "US" } ).first else { return }
                self?.set(country: unitedStatesCountry)
            default: break
            }
        }

        self.delegate?.refreshUI()
    }

    func loadConfig(completion: ((Result<Config>) -> Void)? = nil) {

        self.application?.loadConfig(completion: { [weak self] (configResult) in
            switch configResult {
            case .success(let config):

                if let selectedHowHear = self?.howHearField?.howHear, config.howHearList.contains(selectedHowHear) == false {
                    self?.delegate?.refreshHowHearField(with: nil)
                }

            default: break
            }

            completion?(configResult)
        })
    }

    func registerEmailField(_ emailField: ValidatableField) {

        let emailRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Email field is required.",
                                                                          comment: "Email validataion message")),
                                  EmailRule(message: NSLocalizedString("The Email is wrong",
                                                                       comment: "Email validataion message"))]
        self.validator.registerField(emailField, rules: emailRules)

        self.emailField = emailField

        if emailField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: emailField, didValidate: nil)
        } else {
            self.validator.validateField(emailField) { (validationError) in }
        }
    }

    func registerPasswordField(_ passwordField: ValidatableField) {

        let passwordRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Password field is required.",
                                                                             comment: "Password validataion message")),
                                     MinLengthRule(length: 6,
                                                   message: NSLocalizedString("The Password must be at least %ld characters",
                                                                              comment: "Password validataion template"))]
        self.validator.registerField(passwordField, rules: passwordRules)

        self.passwordField = passwordField

        self.delegate?.refreshField(field: passwordField, didValidate: nil)
    }

    func registerPasswordConfirmationField(_ passwordConfirmationField: ValidatableField, passwordField: ValidatableField) {
        let passwordConfirmationRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Repeat Password field is required.",
                                                                                         comment: "Repeat Password validataion message")),
                                                 ConfirmationRule(confirmField: passwordField,
                                                                  message: NSLocalizedString("Your Password and Repeat Password do not match.",
                                                                                             comment: "Repeat Password validataion message"))]

        self.validator.registerField(passwordConfirmationField, rules: passwordConfirmationRules)

        self.passwordConfirmationField = passwordConfirmationField

        self.delegate?.refreshField(field: passwordConfirmationField, didValidate: nil)
    }

    func registerNicknameField(_ nicknameField: ValidatableField) {
        let nicknameRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Nickname field is required.",
                                                                             comment: "Nickname validataion message"))]
        self.validator.registerField(nicknameField, rules: nicknameRules)

        self.nicknameField = nicknameField

        if nicknameField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: nicknameField, didValidate: nil)
        } else {
            self.validator.validateField(nicknameField) { (validationError) in }
        }
    }

    func registerFirstNameField(_ firstNameField: ValidatableField) {
        let firstNameRules: [Rule] = [RequiredRule(message: NSLocalizedString("The First Name field is required.",
                                                                              comment: "First Name validataion message"))]
        self.validator.registerField(firstNameField, rules: firstNameRules)

        self.firstNameField = firstNameField

        if firstNameField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: firstNameField, didValidate: nil)
        } else {
            self.validator.validateField(firstNameField) { (validationError) in }
        }
    }

    func registerGenderField(_ genderField: GenderValidatableField) {
        let genderRules: [Rule] = []
        
        self.validator.registerField(genderField, rules: genderRules)

        self.genderField = genderField

        self.delegate?.refreshField(field: genderField, didValidate: nil)
    }

    func registerBirhDateField(_ birthDateField: DateValidatableField) {
        let birthDateRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Birth Date field is required.",
                                                                              comment: "Birth Date validataion message"))]

        self.validator.registerField(birthDateField, rules: birthDateRules)

        self.birthDateField = birthDateField

        if birthDateField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: birthDateField, didValidate: nil)
        } else {
            self.validator.validateField(birthDateField) { (validationError) in }
        }
    }

    func registerCountryField(_ countryField: CountryValidatableField) {
        let countryRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Country field is required",
                                                                            comment: "Country validataion message"))]

        self.validator.registerField(countryField, rules: countryRules)

        self.countryField = countryField

        if countryField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: countryField, didValidate: nil)
        } else {
            self.validator.validateField(countryField) { (validationError) in }
        }
    }

    func registerZipField(_ zipField: ValidatableField) {
        let zipRules: [Rule] = []

        self.validator.registerField(zipField, rules: zipRules)

        self.zipField = zipField

        if zipField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: zipField, didValidate: nil)
        } else {
            self.validator.validateField(zipField) { (validationError) in }
        }
    }

    func registerRegionField(_ regionField: RegionValidatableField) {
        let regionRules: [Rule] = []

        self.validator.registerField(regionField, rules: regionRules)

        self.regionField = regionField

        if regionField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: regionField, didValidate: nil)
        } else {
            self.validator.validateField(regionField) { (validationError) in }
        }
    }

    func registerCityField(_ cityField: CityValidatableField) {
        let cityRules: [Rule] = []

        self.validator.registerField(cityField, rules: cityRules )

        self.cityField = cityField

        if cityField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: cityField, didValidate: nil)
        } else {
            self.validator.validateField(cityField) { (validationError) in }
        }
    }

    func registerPhoneField(_ phoneField: MaskedValidatebleField) {
        let phoneRules: [Rule] = []

        self.validator.registerField(phoneField, rules: phoneRules )

        self.phoneField = phoneField

        if phoneField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: phoneField, didValidate: nil)
        } else {
            self.validator.validateField(phoneField) { (validationError) in }
        }
    }

    func registerHobbiesField(_ hobbiesField: HobbiesValidatableField) {
        let hobbiesRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Hobbies field is required.",
                                                                            comment: "Hobbies validataion message"))]

        self.validator.registerField(hobbiesField, rules: hobbiesRules)

        self.hobbiesField = hobbiesField

        if hobbiesField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: hobbiesField, didValidate: nil)
        } else {
            self.validator.validateField(hobbiesField) { (validationError) in }
        }
    }

    func registerHowHearField(_ howHearField: HowHearValidatableField) {
        let howHearRules: [Rule] = [RequiredRule(message: NSLocalizedString("The How Hear field is required.", comment: "How Hear validataion message"))]

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

        if validateField === self.passwordField,
            let passwordConfirmationField = self.passwordConfirmationField,
            !passwordConfirmationField.validationText.isEmpty {
            self.validator.validateField(passwordConfirmationField) { (validationError) in }
        }
    }

    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "email": return self.emailField
        case "password": return self.passwordField
        case "password_confirmation": return self.passwordConfirmationField
        case "nick_name": return self.nicknameField
        case "real_name": return self.firstNameField
        case "gender": return self.genderField
        case "birth_date": return self.birthDateField
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

    func showContriesSelectableList() {
        self.router?.showContriesSelectableList(dataSource: self, selectedItem: self.countryField?.country, selectionCallback: { [weak self] (country) in
            self?.set(country: country)
        })
    }
    func showRegionsSelectableList() {
        self.router?.showRegionsSelectableList(dataSource: self, selectedItem: self.regionField?.region, selectionCallback: { [weak self] (region) in
            self?.set(region: region)
        })
    }
    func showCitiesSelectableList() {
        self.router?.showCitiesSelectableList(dataSource: self, selectedItem: self.cityField?.city, selectionCallback: { [weak self] (city) in
            self?.set(city: city)
        })
    }

    func showHobbiesSelectableList() {

        let selectedHobbies = self.hobbiesField?.hobbies

        self.router?.showHobbiesSelectableList(dataSource: self,
                                               selectedItems: selectedHobbies,
                                               additionalItems: [],
                                               selectionCallback: { [weak self] (hobbies) in
                                                    self?.set(hobbies: hobbies)
                                            })
    }

    func showHowHearSelectableList() {
        self.router?.showHowHearSelectableList(dataSource: self, selectedItem: self.howHearField?.howHear, selectionCallback: { [weak self] (howHear) in
            self?.set(howHear: howHear)
        })
    }

    func getLocation() {

        guard let countryField = self.countryField, let zipField = self.zipField else { return }

        var countryFieldValidationError: ValidationError?
        var zipFieldValidationError: ValidationError?

        self.validator.validateField(countryField) { (validationError) in countryFieldValidationError = validationError }
        self.validator.validateField(zipField) { (validationError) in zipFieldValidationError = validationError }

        guard countryFieldValidationError == nil && zipFieldValidationError == nil,
            let country = countryField.country else { return }

        let _ =
        ConfigRequest.location(for: country, zip: zipField.validationText)
            .rx.baseResponse(type: DetailedLocation.self)
            .subscribe(onSuccess: { [weak self] (detailedLocation) in
                
                guard let `self` = self else { return }
                guard let countryField = self.countryField, let zipField = self.zipField,
                    let regionField = self.regionField, let cityField = self.cityField else { return }
                
                self.regions = detailedLocation.regions
                self.cities = detailedLocation.cities
                
                self.delegate?.refreshCountryField(with: detailedLocation.country)
                self.validator.validateField(countryField, callback: { (validationError) in })
                self.delegate?.refreshZipField(with: detailedLocation.zip)
                self.validator.validateField(zipField, callback: { (validationError) in })
                self.delegate?.refreshRegionField(with: detailedLocation.region)
                self.validator.validateField(regionField, callback: { (validationError) in })
                self.delegate?.refreshCityField(with: detailedLocation.city)
                self.validator.validateField(cityField, callback: { (validationError) in })
                
            }, onError: { [weak self] error in
                
                guard let s = self else { return }
                
                guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                    s.delegate?.show(error: error)
                    return
                }
                
                switch appErrorGroup {
                case RestApiServiceError.serverError( let errorDescription, _ ):
                    
                    let validationError = ValidationError(field: s.regionField!, errorLabel: nil, error: errorDescription)
                    self?.delegate?.refreshField(field: s.regionField!, didValidate: validationError)
                    
                default:
                    s.delegate?.show(error: error)
                }
                
            })
        
    }

    func signUp() {

        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText,
                let password = self.passwordField?.validationText,
                let passwordConfirmation = self.passwordConfirmationField?.validationText,
                let nickname = self.nicknameField?.validationText,
                let firstName = self.firstNameField?.validationText,
                let birhDate = self.birthDateField?.date,
                let country = self.countryField?.country,
                let phone = self.phoneField?.validationText,
                let hobbies = self.hobbiesField?.hobbies,
                let howHear = self.howHearField?.howHear else { return }

            let location = ProfileLocation(country: country,
                                           region: self.regionField?.region,
                                           city: self.cityField?.city,
                                           zip: self.zipField?.validationText)
            
            let registrationPayload = RegisterData(email: email,
                                                                               password: password,
                                                                               passwordConfirmation: passwordConfirmation,
                                                                               nickname: nickname,
                                                                               realName: firstName,
                                                                               birthDate: birhDate,
                                                                               gender: self.genderField?.gender,
                                                                               location: location,
                                                                               phone: phone,
                                                                               hobbies: hobbies,
                                                                               howHear: howHear)

            let _ =
            UserRequest.register(data: registrationPayload)
                .rx.baseResponse(type: FanRegistrationResponse.self)
                .subscribe(onSuccess: { (resp) in
                    
                    self.registeredUserProfile = resp.userProfile
                    self.delegate?.refreshUI()
                    
                }, onError: { error in
                    
                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                        self.delegate?.show(error: error)
                        return
                    }
                    
                    switch appErrorGroup {
                    case RestApiServiceError.serverError( let errorDescription, let errors):
                        self.signUpErrorDescription = errorDescription
                        for (key, errorStrings) in errors {
                            guard let validatebleField = self.validatebleField(for: key), let validatebleFieldErrorString = errorStrings.first else { continue }
                            
                            let validationError = ValidationError(field: validatebleField, errorLabel: nil, error: validatebleFieldErrorString)
                            self.delegate?.refreshField(field: validatebleField, didValidate: validationError)
                        }
                        
                    default:
                        self.delegate?.show(error: error)
                    }
                    
                    self.delegate?.refreshUI()
                    
                })

        }
    }
}

// MARK: - CountriesDataProvider -

extension SignUpControllerViewModel {

    func reloadCountries(completion: @escaping (Result<[Country]>) -> Void) {
        
        let _ =
        ConfigRequest.countries.rx.response(type: [Country].self)
            .subscribe(onSuccess: { [weak self] (countries) in
                
                self?.countries = countries
                if let selectedCountry = self?.countryField?.country, countries.contains(selectedCountry) == false {
                    self?.delegate?.refreshCountryField(with: nil)
                }
                completion(.success(countries))
                
            })
        
    }

    func reloadRegions(completion: @escaping (Result<[Region]>) -> Void) {
        guard let country = self.countryField?.country else { completion(.success([])); return }

        let _ =
        ConfigRequest.regions(for: country).rx.response(type: [Region].self)
            .subscribe(onSuccess: { [weak self] (regions) in
                
                self?.regions = regions
                if let selectedRegion = self?.regionField?.region, regions.contains(selectedRegion) == false {
                    self?.delegate?.refreshRegionField(with: nil)
                }
                completion(.success(regions))
                
            })
        
    }

    func reloadCities(completion: @escaping (Result<[City]>) -> Void) {
        guard let region = self.regionField?.region else { completion(.success([])); return }

        let _ =
        ConfigRequest.cities(for: region).rx.response(type: [City].self)
            .subscribe(onSuccess: { [weak self] (cities) in
                
                self?.cities = cities
                if let selectedCity = self?.cityField?.city, cities.contains(selectedCity) == false {
                    self?.delegate?.refreshCityField(with: nil)
                }
                completion(.success(cities))
                
            })
        
    }

    // MARK: - HobbiesDataSource -
    var hobbies: [Hobby] { return self.hobbies(for: self.application?.config?.hobbies ?? []) }

    func hobbies(for loadedHobbies: [Hobby]) -> [Hobby] {
        let selectedAdditionalHobbies = self.hobbiesField?.hobbies?.filter { $0.id == nil } ?? []

        var hobbies = loadedHobbies
        hobbies.append(contentsOf: selectedAdditionalHobbies)

        return hobbies
    }

    func reloadHobbies(completion: @escaping (Result<[Hobby]>) -> Void) {
        self.loadConfig { [weak self] (configResult) in

            guard let `self` = self else { return }

            switch configResult {
            case .success(let config):
                let hobbies = self.hobbies(for: config.hobbies)
                completion(.success(hobbies))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func reloadHowHearList(completion: @escaping (Result<[HowHear]>) -> Void) {
        self.loadConfig { (configResult) in
            switch configResult {
            case .success(let config):
                completion(.success(config.howHearList))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
