//
//  ProfileSettingsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator
import Alamofire

final class ProfileSettingsControllerViewModel: ProfileSettingsViewModel {

    // MARK: - Public properties -

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: ProfileSettingsViewModelDelegate?
    private(set) weak var router: ProfileSettingsRouter?
    private(set) weak var application: Application?
    private(set) weak var restApiService: RestApiService?

    private(set) var countries: [Country]
    private(set) var regions: [Region]
    private(set) var cities: [City]
    var hobbies: [Hobby] { return self.application?.config?.hobbies ?? [] }
    private(set) var genres: [Genre]
    var languages: [Language] { return self.application?.config?.languages ?? [] }

    private let validator: Validator

    private(set) var canSave: Bool = false
    private(set) var profileSettingsErrorDescription: String?

    private var userProfile: UserProfile?

    private var firstNameField: ValidatableField?
    private var nicknameField: ValidatableField?
    private var genderField: GenderValidatableField?
    private var birthDateField: DateValidatableField?

    private var countryField: CountryValidatableField?
    private var zipField: ValidatableField?
    private var regionField: RegionValidatableField?
    private var cityField: CityValidatableField?
    private var phoneField: ValidatableField?

    private var hobbiesField: HobbiesValidatableField?
    private var genresField: GenresValidatableField?
    private var languageField: LanguageValidatableField?

    // MARK: - Lifecycle -

    init(router: ProfileSettingsRouter, application: Application, restApiService: RestApiService) {
        self.router = router
        self.application = application
        self.restApiService = restApiService
        self.validator = Validator()

        self.countries = []
        self.regions = []
        self.cities = []
        self.genres = []
    }

    func refreshDelegate(with userProfile: UserProfile) {

        self.delegate?.refreshFirstNameField(with: userProfile.firstName)
        self.delegate?.refreshNickNameField(with: userProfile.nickname)
        self.delegate?.refreshGenderField(with: userProfile.gender)
        self.delegate?.refreshBirthDateField(with: userProfile.birthDate)
        self.delegate?.refreshCountryField(with: Country(with: userProfile.location.country))
        self.delegate?.refreshZipField(with: userProfile.location.zip)
        self.delegate?.refreshRegionField(with: Region(with: userProfile.location.region))
        self.delegate?.refreshCityField(with: City(with: userProfile.location.city))
        self.delegate?.refreshPhoneField(with: userProfile.phone)
        self.delegate?.refreshHobbiesField(with: userProfile.hobbies)
        self.delegate?.refreshGenresField(with: userProfile.genres)

        if let selectedLanguageId = userProfile.language, let selectedLanguage = self.languages.filter( {$0.id == selectedLanguageId} ).first {
            self.delegate?.refreshLanguageField(with: selectedLanguage)
        }

        self.delegate?.refreshUI()
    }

    func load(with delegate: ProfileSettingsViewModelDelegate) {
        self.delegate = delegate

        guard let fanUser = self.application?.user as? FanUser else { return }

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
                self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })

        self.userProfile = fanUser.profile
        self.refreshDelegate(with: fanUser.profile)

        if self.application?.config == nil {
            self.loadConfig { [weak self] (configResult) in
                switch configResult {
                case .success( _): self?.loadUser()
                case .failure(let error): self?.delegate?.show(error: error)
                }
            }
        } else {
            self.loadUser()
        }
    }

    func loadUser() {
        self.application?.fanUser(completion: { (fanUserResult) in
            switch fanUserResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { return }

                self.userProfile = fanUser.profile
                self.refreshDelegate(with: fanUser.profile)

            case .failure(let error):
                self.delegate?.show(error: error)
            }
        })
    }

    func loadConfig(completion: @escaping (Result<Config>) -> Void) {

        self.application?.loadConfig(completion: { [weak self] (configResult) in
            switch configResult {
            case .success(let config):

                if let selectedHobbies = self?.hobbiesField?.hobbies, selectedHobbies.count > 0 {
                    let filteredSelectedHobbies = selectedHobbies.filter( { return config.hobbies.contains($0) })
                    self?.delegate?.refreshHobbiesField(with: filteredSelectedHobbies)
                }

                if let selectedLanguageId = self?.userProfile?.language, let selectedLanguage = config.languages.filter( {$0.id == selectedLanguageId} ).first {
                    self?.delegate?.refreshLanguageField(with: selectedLanguage)
                }

            default: break
            }

            completion(configResult)
        })
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

    func registerGenderField(_ genderField: GenderValidatableField) {
        let genderRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Gender field is required.",
                                                                           comment: "Gender validataion message"))]
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
        let zipRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Zip field is required",
                                                                        comment: "Zip validataion message")),
                                MaxLengthRule(length: 15, message: NSLocalizedString("Max length is %ld",
                                                                                     comment: "Zip validataion template"))]
        self.validator.registerField(zipField, rules: zipRules)

        self.zipField = zipField

        if zipField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: zipField, didValidate: nil)
        } else {
            self.validator.validateField(zipField) { (validationError) in }
        }
    }

    func registerRegionField(_ regionField: RegionValidatableField) {
        let regionRules: [Rule] = [RequiredRule(message: NSLocalizedString("The State field is required.",
                                                                           comment: "State validataion message"))]
        self.validator.registerField(regionField, rules: regionRules)

        self.regionField = regionField

        if regionField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: regionField, didValidate: nil)
        } else {
            self.validator.validateField(regionField) { (validationError) in }
        }
    }

    func registerCityField(_ cityField: CityValidatableField) {
        let cityRules: [Rule] = [RequiredRule(message: NSLocalizedString("The City field is required.",
                                                                         comment: "City validataion message"))]
        self.validator.registerField(cityField, rules: cityRules )

        self.cityField = cityField

        if cityField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: cityField, didValidate: nil)
        } else {
            self.validator.validateField(cityField) { (validationError) in }
        }
    }

    func registerPhoneField(_ phoneField: ValidatableField) {
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

    func registerGenresField(_ genresField: GenresValidatableField) {
        let genresRules: [Rule] = []

        self.validator.registerField(genresField, rules: genresRules)

        self.genresField = genresField

        if genresField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: genresField, didValidate: nil)
        } else {
            self.validator.validateField(genresField) { (validationError) in }
        }
    }

    func registerLanguageField(_ languageField: LanguageValidatableField) {
        let languageRules: [Rule] = []

        self.validator.registerField(languageField, rules: languageRules)

        self.languageField = languageField

        if languageField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: languageField, didValidate: nil)
        } else {
            self.validator.validateField(languageField) { (validationError) in }
        }
    }

    func checkCanSaveState() {
        guard let userProfile = self.userProfile else { return }

        let isDirty = userProfile.firstName != self.firstNameField?.validationText ||
                        userProfile.nickname != self.nicknameField?.validationText ||
                        userProfile.gender != self.genderField?.gender ||
                        userProfile.birthDate != self.birthDateField?.date ||
                        Country(with: userProfile.location.country) != self.countryField?.country ||
                        userProfile.location.zip != self.zipField?.validationText ||
                        Region(with: userProfile.location.region) != self.regionField?.region ||
                        City(with: userProfile.location.city) != self.cityField?.city ||
                        userProfile.phone ?? "" != self.phoneField?.validationText ||
                        userProfile.hobbies != self.hobbiesField?.hobbies ||
                        userProfile.genres != self.genresField?.genres ||
                        userProfile.language != self.languageField?.language?.id





        if self.canSave != isDirty {
            self.canSave = isDirty
            self.delegate?.refreshUI()
        }
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }

        self.checkCanSaveState()
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

    func set(genres: [Genre]) {
        self.delegate?.refreshGenresField(with: genres)
        self.validateField(self.genresField)
    }

    func set(language: Language) {
        self.delegate?.refreshLanguageField(with: language)
        self.validateField(self.languageField)
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
        self.router?.showHobbiesSelectableList(dataSource: self, selectedItems: self.hobbiesField?.hobbies, selectionCallback: { [weak self] (hobbies) in
            self?.set(hobbies: hobbies)
        })
    }

    func showGenresSelectableList() {
        self.router?.showGenresSelectableList(dataSource: self, selectedItems: self.genresField?.genres, selectionCallback: { [weak self] (genres) in
            self?.set(genres: genres)
        })
    }

    func showLanguagesSelectableList() {
        self.router?.showLanguagesSelectableList(dataSource: self, selectedItems: self.languageField?.language, selectionCallback: { [weak self] (language) in
            self?.set(language: language)
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

        self.restApiService?.location(for: country, zip: zipField.validationText, completion: { [weak self] (detailedLocationResult) in

            guard let `self` = self else { return }
            guard let countryField = self.countryField, let zipField = self.zipField,
                let regionField = self.regionField, let cityField = self.cityField else { return }

            switch detailedLocationResult {
            case .success(let detailedLocation):

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

                self.checkCanSaveState()

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


    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "real_name": return self.firstNameField
        case "nick_name": return self.nicknameField
        case "gender": return self.genderField
        case "birth_date": return self.birthDateField
        case "hobbies": return self.hobbiesField
        case "genres": return self.genderField
        case "language": return self.languageField
        default: break
        }

        return nil
    }

    func save() {
        guard let userProfile = self.userProfile else { return }

        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let firstName = self.firstNameField?.validationText,
                let nickname = self.nicknameField?.validationText,
                let birhDate = self.birthDateField?.date,
                let gender = self.genderField?.gender,
                let country = self.countryField?.country,
                let region = self.regionField?.region,
                let city = self.cityField?.city,
                let zip = self.zipField?.validationText,
                let hobbies = self.hobbiesField?.hobbies,
                let phoneField = self.phoneField else { return }

            var updatingUserProfile = userProfile
            updatingUserProfile.firstName = firstName
            updatingUserProfile.nickname = nickname
            updatingUserProfile.gender = gender
            updatingUserProfile.birthDate = birhDate
            updatingUserProfile.location = ProfileLocation(country: country, region: region, city: city, zip: zip)
            updatingUserProfile.phone = phoneField.validationText.isEmpty ? nil : self.phoneField?.validationText
            updatingUserProfile.hobbies = hobbies
            updatingUserProfile.genres = self.genresField?.genres
            updatingUserProfile.language = self.languageField?.language?.id

            self.application?.update(profileSettings: updatingUserProfile, completion: { [weak self] (userProfileResult) in

                switch (userProfileResult) {
                case .success(let userProfile):
                    self?.userProfile = userProfile
                    self?.refreshDelegate(with: userProfile)
                    self?.checkCanSaveState()


                case .failure(let error):
                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                        self?.delegate?.show(error: error)
                        return
                    }

                    switch appErrorGroup {
                    case RestApiServiceError.serverError( let errorDescription, let errors):
                        self?.profileSettingsErrorDescription = errorDescription
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

extension ProfileSettingsControllerViewModel {

    func reloadCountries(completion: @escaping (Result<[Country]>) -> Void) {
        self.restApiService?.countries(completion: { [weak self] (contriesResult) in
            switch contriesResult {
            case .success(let countries):
                self?.countries = countries
                if let selectedCountry = self?.countryField?.country, countries.contains(selectedCountry) == false {
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
                if let selectedRegion = self?.regionField?.region, regions.contains(selectedRegion) == false {
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
                if let selectedCity = self?.cityField?.city, cities.contains(selectedCity) == false {
                    self?.delegate?.refreshCityField(with: nil)
                }
                completion(.success(cities))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func reloadHobbies(completion: @escaping (Result<[Hobby]>) -> Void) {
        self.loadConfig { (configResult) in
            switch configResult {
            case .success(let config):
                completion(.success(config.hobbies))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func reloadGenres(completion: @escaping (Result<[Genre]>) -> Void) {

        self.restApiService?.genres(completion: { [weak self] (genresResult) in
            switch genresResult {
            case .success(let genres):
                self?.genres = genres

                if let selectedGenres = self?.genresField?.genres, selectedGenres.count > 0 {
                    let filteredSelectedGenres = selectedGenres.filter( { return genres.contains($0) })
                    self?.delegate?.refreshGenresField(with: filteredSelectedGenres)
                }
                completion(.success(genres))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    func reloadLanguages(completion: @escaping (Result<[Language]>) -> Void) {
        self.loadConfig { (configResult) in
            switch configResult {
            case .success(let config):
                completion(.success(config.languages))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}
