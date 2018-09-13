//
//  ProfileSettingsViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol ProfileSettingsViewModel: CountriesDataSource, RegionsDataSource, CitiesDataSource, HobbiesDataSource, GenresDataSource, LanguagesDataSource {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var countries: [Country] { get }
    var regions: [Region] { get }
    var cities: [City] { get }
    var hobbies: [Hobby] { get }
    var genres: [Genre] { get }
    var languages: [Language] { get }

    var canSave: Bool { get }
    var profileSettingsErrorDescription: String? { get }

    func load(with delegate: ProfileSettingsViewModelDelegate)

    func registerFirstNameField(_ firstNameField: ValidatableField)
    func registerNicknameField(_ nicknameField: ValidatableField)
    func registerGenderField(_ genderField: GenderValidatableField)
    func registerBirhDateField(_ birthDateField: DateValidatableField)

    func registerCountryField(_ countryField: CountryValidatableField)
    func registerZipField(_ zipField: ValidatableField)
    func registerRegionField(_ regionField: RegionValidatableField)
    func registerCityField(_ cityField: CityValidatableField)
    func registerPhoneField(_ phoneField: ValidatableField)

    func registerHobbiesField(_ hobbiesField: HobbiesValidatableField)
    func registerGenresField(_ genresField: GenresValidatableField)
    func registerLanguageField(_ languageField: LanguageValidatableField)

    func validateField(_ validateField: ValidatableField?)

    func showContriesSelectableList()
    func showRegionsSelectableList()
    func showCitiesSelectableList()
    func showHobbiesSelectableList()
    func showGenresSelectableList()
    func showLanguagesSelectableList()

    func getLocation()
    func save()
}

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
