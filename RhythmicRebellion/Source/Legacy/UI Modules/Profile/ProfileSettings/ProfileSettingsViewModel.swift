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


protocol ProfileSettingsViewModelDelegate: class, ErrorPresenting {
    
    func refreshUI()
    func refreshField(field: ValidatableField, didValidate error: ValidationError?)
    
    func refreshFirstNameField(with name: String?)
    func refreshNickNameField(with name: String?)
    func refreshGenderField(with gender: Gender?)
    func refreshBirthDateField(with date: Date?)
    
    func refreshCountryField(with country: Country?)
    func refreshZipField(with zip: String?)
    func refreshRegionField(with region: Region?)
    func refreshCityField(with city: City?)
    func refreshPhoneField(with phone: String?)
    
    func refreshHobbiesField(with hobbies: [Hobby]?)
    func refreshGenresField(with genres: [Genre]?)
    func refreshLanguageField(with language: Language?)
}


final class ProfileSettingsViewModel: CountriesDataSource, RegionsDataSource, CitiesDataSource, HobbiesDataSource, GenresDataSource, LanguagesDataSource {

    // MARK: - Public properties -

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: ProfileSettingsViewModelDelegate?
    private(set) weak var router: ProfileSettingsRouter?
    
    

    private(set) var countries: [Country]
    private(set) var regions: [Region]
    private(set) var cities: [City]
    private(set) var loadedGenres: [Genre]
    var languages: [Language] { return self.config?.languages ?? [] }

    private let validator: Validator

    private(set) var isDirty: Bool = false
    private(set) var profileSettingsErrorDescription: String?

    private var userProfile: UserProfile?

    private var firstNameField: ValidatableField?
    private var nicknameField: ValidatableField?
    private var genderField: GenderSegmentedControl?
    private var birthDateField: DateTextField?

    private var countryField: CountryTextField?
    private var zipField: ValidatableField?
    private var regionField: RegionTextField?
    private var cityField: CityTextField?
    private var phoneField: MaskedFieldWrapperWrapper?

    private var hobbiesField: HobbiesContainerView?
    private var genresField: GenresContainerView?
    private var languageField: LanguageTextField?

    var config: Config?
    
    // MARK: - Lifecycle -

    init(router: ProfileSettingsRouter) {
        self.router = router
        
        
        self.validator = Validator()

        self.countries = []
        self.regions = []
        self.cities = []
        self.loadedGenres = []
    }

    func refreshDelegate(with userProfile: UserProfile) {

        self.delegate?.refreshFirstNameField(with: userProfile.firstName)
        self.delegate?.refreshNickNameField(with: userProfile.nickname)
        self.delegate?.refreshGenderField(with: userProfile.gender)
        self.delegate?.refreshBirthDateField(with: userProfile.birthDate)
        self.delegate?.refreshCountryField(with: Country(with: userProfile.location.country))
        self.delegate?.refreshZipField(with: userProfile.location.zip)
        self.delegate?.refreshRegionField(with: userProfile.location.region)
        self.delegate?.refreshCityField(with: userProfile.location.city)
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

        guard let profile = appStateSlice.user.profile else { return }

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
                self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })

        self.userProfile = profile
        self.refreshDelegate(with: profile)

        if self.config == nil {
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
        
        let _ =
        UserRequest.login.rx.baseResponse(type: User.self)
            .subscribe(onSuccess: { (user) in
                
                if let p = user.profile {
                    self.userProfile = p
                    self.refreshDelegate(with: p)
                }
                
            }, onError: { error in
                self.delegate?.show(error: error)
            })

    }

    func loadConfig(completion: @escaping (Result<Config>) -> Void) {

        let _ =
        ConfigRequest.user.rx.baseResponse(type: Config.self)
            .subscribe(onSuccess: { [weak self] (config) in
                
                if let selectedLanguageId = self?.userProfile?.language, let selectedLanguage = config.languages.filter( {$0.id == selectedLanguageId} ).first {
                    self?.delegate?.refreshLanguageField(with: selectedLanguage)
                }
                
                self?.config = config
                
                completion(.success(config))
                
            })
        
    }

    func unsavedChangesConfirmationViewModel() {

        router?.sourceController?.presentConfirmQuestion(question: DisplayMessage(title: "Warning", description: "You have unsaved changes. Press Cancel to go back and save these changes,or OK to lose these changes"))
            .filter { $0 }
            .subscribe(onNext: { [weak self] (_) in
                self?.router?.navigateBack()
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

    func registerGenderField(_ genderField: GenderSegmentedControl) {
        let genderRules: [Rule] = []
        
        self.validator.registerField(genderField, rules: genderRules)

        self.genderField = genderField

        self.delegate?.refreshField(field: genderField, didValidate: nil)
    }

    func registerBirhDateField(_ birthDateField: DateTextField) {
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

    func registerCountryField(_ countryField: CountryTextField) {
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
        let zipRules: [Rule] = [MaxLengthRule(length: 15,
                                              message: "Max length is 15")]
        
        self.validator.registerField(zipField, rules: zipRules)

        self.zipField = zipField

        if zipField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: zipField, didValidate: nil)
        } else {
            self.validator.validateField(zipField) { (validationError) in }
        }
    }

    func registerRegionField(_ regionField: RegionTextField) {
        let regionRules: [Rule] = []
        
        self.validator.registerField(regionField, rules: regionRules)

        self.regionField = regionField

        if regionField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: regionField, didValidate: nil)
        } else {
            self.validator.validateField(regionField) { (validationError) in }
        }
    }

    func registerCityField(_ cityField: CityTextField) {
        let cityRules: [Rule] = []
        
        self.validator.registerField(cityField, rules: cityRules )

        self.cityField = cityField

        if cityField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: cityField, didValidate: nil)
        } else {
            self.validator.validateField(cityField) { (validationError) in }
        }
    }

    func registerPhoneField(_ phoneField: MaskedFieldWrapperWrapper) {
        let phoneRules: [Rule] = []

        self.validator.registerField(phoneField, rules: phoneRules )

        self.phoneField = phoneField

        if phoneField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: phoneField, didValidate: nil)
        } else {
            self.validator.validateField(phoneField) { (validationError) in }
        }
    }

    func registerHobbiesField(_ hobbiesField: HobbiesContainerView) {
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

    func registerGenresField(_ genresField: GenresContainerView) {
        let genresRules: [Rule] = []

        self.validator.registerField(genresField, rules: genresRules)

        self.genresField = genresField

        if genresField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: genresField, didValidate: nil)
        } else {
            self.validator.validateField(genresField) { (validationError) in }
        }
    }

    func registerLanguageField(_ languageField: LanguageTextField) {
        let languageRules: [Rule] = []

        self.validator.registerField(languageField, rules: languageRules)

        self.languageField = languageField

        if languageField.validationText.isEmpty == true {
            self.delegate?.refreshField(field: languageField, didValidate: nil)
        } else {
            self.validator.validateField(languageField) { (validationError) in }
        }
    }

    func checkIsDirty() {
        guard let userProfile = self.userProfile else { return }

        let isDirty = userProfile.firstName != self.firstNameField?.validationText ||
                        userProfile.nickname != self.nicknameField?.validationText ||
                        userProfile.gender != self.genderField?.gender ||
                        userProfile.birthDate != self.birthDateField?.date ||
                        Country(with: userProfile.location.country) != self.countryField?.country ||
                        userProfile.location.zip != self.zipField?.validationText ||
                        userProfile.location.region != self.regionField?.region ||
                        userProfile.location.city != self.cityField?.city ||
                        userProfile.phone ?? "" != self.phoneField?.validationText ||
                        userProfile.hobbies != self.hobbiesField?.hobbies ||
                        userProfile.genres != self.genresField?.genres ||
                        userProfile.language != self.languageField?.language?.id

        if self.isDirty != isDirty {
            self.isDirty = isDirty
            self.delegate?.refreshUI()
        }
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }

        self.checkIsDirty()
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

        let currentItems = self.hobbiesField?.hobbies ?? []
        var newItems = hobbies
        var mergedItems = [Hobby]()

        for currentItem in currentItems {
            guard let currentGenreIndex = newItems.index(of: currentItem) else {
                continue
            }

            mergedItems.append(currentItem);
            newItems.remove(at: currentGenreIndex)
        }

        mergedItems.append(contentsOf: newItems)


        self.delegate?.refreshHobbiesField(with: mergedItems)
        self.validateField(self.hobbiesField)
    }

    func set(genres: [Genre]) {

        let additionalGenress = self.userProfile?.genres?.filter { $0.id == nil} ?? []
        let currentItems = self.genresField?.genres ?? []
        var newItems = genres
        var mergedItems = [Genre]()

        for currentItem in currentItems {
            guard let currentGenreIndex = newItems.index(of: currentItem) else {
                guard currentItem.id == nil, additionalGenress.contains(currentItem) else { continue }
                mergedItems.append(currentItem);
                continue
            }

            mergedItems.append(currentItem);
            newItems.remove(at: currentGenreIndex)
        }

        mergedItems.append(contentsOf: newItems)

        self.delegate?.refreshGenresField(with: mergedItems)
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

        let selectedHobbies = self.hobbiesField?.hobbies ?? []

        self.router?.showHobbiesSelectableList(dataSource: self,
                                               selectedItems: selectedHobbies,
                                               additionalItems: [],
                                               selectionCallback: { [weak self] (hobbies) in
                                                    self?.set(hobbies: hobbies)
                                            })
    }

    func showGenresSelectableList() {

        let additionalGenres = self.userProfile?.genres?.filter { $0.id == nil && self.genresField?.genres?.contains($0) ?? false }
        let selectedGenres = self.genresField?.genres?.filter { $0.id != nil || additionalGenres?.contains($0) == false } ?? []

        self.router?.showGenresSelectableList(dataSource: self,
                                              selectedItems: selectedGenres,
                                              additionalItems: additionalGenres,
                                              selectionCallback: { [weak self] (genres) in
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
                    
                    guard let appError = error as? RRError,
                        case .server(let e) = appError else {
                            s.delegate?.show(error: error)
                            return
                    }
                    
                    for (key, errorStrings) in e.errors {
                        guard let x = s.validatebleField(for: key),
                            let s = errorStrings.first else { continue }
                        
                        let validationError = ValidationError(field: x,
                                                              errorLabel: nil,
                                                              error: s)
                        
                        self?.delegate?.refreshField(field: x,
                                                     didValidate: validationError)
                    }
                    
                    s.delegate?.refreshUI()
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
                let country = self.countryField?.country,
                let hobbies = self.hobbiesField?.hobbies,
                let phoneField = self.phoneField else { return }

            var updatingUserProfile = userProfile
            updatingUserProfile.firstName = firstName
            updatingUserProfile.nickname = nickname
            updatingUserProfile.gender = self.genderField?.gender
            updatingUserProfile.birthDate = birhDate
            updatingUserProfile.location = ProfileLocation(country: country,
                                                           region: regionField?.region,
                                                           city: cityField?.city, zip: zipField?.validationText)
            updatingUserProfile.phone = phoneField.validationText.isEmpty ? nil : self.phoneField?.validationText
            updatingUserProfile.hobbies = hobbies
            updatingUserProfile.genres = self.genresField?.genres
            updatingUserProfile.language = self.languageField?.language?.id

            let _ =
            UserRequest.updateProfile(UserProfilePayload(with: updatingUserProfile))
                .rx.baseResponse(type: User.self)
                .subscribe(onSuccess: { (user) in
                    
                    self.userProfile = user.profile
                    if let p = user.profile {
                        self.refreshDelegate(with: p)
                    }
                    self.checkIsDirty()
                    self.navigateBack()
                    
                }, onError: { [weak self] error in
                    
                    guard let s = self else { return }
                    
                    guard let appError = error as? RRError,
                        case .server(let e) = appError else {
                            s.delegate?.show(error: error)
                            return
                    }
                    
                    for (key, errorStrings) in e.errors {
                        guard let x = s.validatebleField(for: key),
                            let s = errorStrings.first else { continue }
                        
                        let validationError = ValidationError(field: x,
                                                              errorLabel: nil,
                                                              error: s)
                        
                        self?.delegate?.refreshField(field: x,
                                                     didValidate: validationError)
                    }
                    
                    s.delegate?.refreshUI()
                    
                })
            
        }
    }

    func navigateBack() {
        self.router?.navigateBack()
    }
}

extension ProfileSettingsViewModel {

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
    var hobbies: [Hobby] { return self.hobbies(for: self.config?.hobbies ?? []) }

    func hobbies(for loadedHobbies: [Hobby]) -> [Hobby] {
        
        let selectedAdditionalHobbies = self.hobbiesField?.hobbies ?? []

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

    // MARK: - GenresDataSource -
    var genres: [Genre] {
        return self.genres(for: self.loadedGenres)
    }

    func genres(for loadedGenres: [Genre]) -> [Genre] {
        let additionalGenres = self.userProfile?.genres?.filter { $0.id == nil}
        let selectedAdditionalGenres = self.genresField?.genres?.filter { $0.id == nil && additionalGenres?.contains($0) == false } ?? []

        var genres = loadedGenres
        genres.append(contentsOf: selectedAdditionalGenres)

        return genres

    }

    func reloadGenres(completion: @escaping (Result<[Genre]>) -> Void) {

        let _ =
        ConfigRequest.genres.rx.baseResponse(type: [Genre].self)
            .subscribe(onSuccess: { [weak self] (loadedGenres) in
                
                self?.loadedGenres = loadedGenres
                let genres = self?.genres(for: loadedGenres)
                completion(.success(genres ?? []))
                
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
