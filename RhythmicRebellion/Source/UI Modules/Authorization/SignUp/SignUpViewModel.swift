//
//  SignUpViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol SignUpViewModel: CountriesDataSource, RegionsDataSource, CitiesDataSource, HobbiesDataSource, HowHearListDataSource {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var isSignUpSucced: Bool { get }

    var countries: [Country] { get }
    var selectedCountry: Country? { get }

    var regions: [Region] { get }
    var selectedRegion: Region? { get }

    var cities: [City] { get }
    var selectedCity: City? { get }

    var hobbies: [Hobby] { get}
    var selectedHobbies: [Hobby]? { get }

    var howHearList: [HowHear] { get }
    var selectedHowHear: HowHear? { get }

    var signUpErrorDescription: String? { get }

    func load(with delegate: SignUpViewModelDelegate)

    func registerEmailField(_ emailField: ValidatableField)
    func registerPasswordField(_ passwordField: ValidatableField)
    func registerPasswordConfirmationField(_ passwordConfirmationField: ValidatableField, passwordField: ValidatableField)
    func registerNicknameField(_ nicknameField: ValidatableField)
    func registerFirstnameField(_ firstnameField: ValidatableField)
    func registerGenderField(_ genderField: GenderValidatableField)
    func registerBirhdateField(_ birthdateField: DateValidatableField)
    func registerCountryField(_ countryField: CountryValidatableField)
    func registerZipField(_ zipField: ValidatableField)
    func registerRegionField(_ regionField: RegionValidatableField)
    func registerCityField(_ cityField: CityValidatableField)
    func registerPhoneField(_ phoneField: ValidatableField)
    func registerHobbiesField(_ hobbiesField: HobbiesValidatableField)
    func registerHowHearField(_ howHearField: HowHearValidatableField)

    func validateField(_ validateField: ValidatableField?)

    func set(country: Country)
    func set(region: Region)
    func set(city: City)
    func set(hobbies: [Hobby])
    func set(howHear: HowHear)

    func showContriesSelectableList()
    func showRegionsSelectableList()
    func showCitiesSelectableList()
    func showHobbiesSelectableList()
    func showHowHearSelectableList()

    func getLocation()
    func signUp()
}

protocol SignUpViewModelDelegate: class, ErrorPresnting{

    func refreshUI()
    func refreshField(field: ValidatableField, didValidate error: ValidationError?)

    func refreshCountryField(with country: Country?)
    func refreshZipField(with zip: String?)
    func refreshRegionField(with region: Region?)
    func refreshCityField(with city: City?)
    func refreshHobbiesField(with hobbies: [Hobby])
    func refreshHowHearField(with howHear: HowHear?)
}
