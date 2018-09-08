//
//  RestApiRequestPayloads.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/25/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol RestApiRequestPayload: Encodable {

}

protocol RestApiProfileRequestPayload: RestApiRequestPayload {

}

struct RestApiListeningSettingsRequestPayload: RestApiProfileRequestPayload {

    let listeningSettings: ListeningSettings

    init(with listeningSettings: ListeningSettings) {
        self.listeningSettings = listeningSettings
    }

    enum CodingKeys: String, CodingKey {
        case listeningSettings = "listening_settings"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(listeningSettings, forKey: .listeningSettings)
    }
}

struct RestApiFanUserRegistrationRequestPayload: RestApiRequestPayload {

    let email: String
    let password: String
    var passwordConfirmation: String
    var nickName: String
    var realName: String
    var birthDate: Date
    var gender: Gender
    var location: Location
    var phone: String?
    var hobbies: [Hobby]
    var howHear: HowHear


    enum CodingKeys: String, CodingKey {
        case email
        case password
        case passwordConfirmation = "password_confirmation"
        case nickName = "nick_name"
        case realName = "real_name"
        case birthDate = "birth_date"
        case gender
        case location
        case phone
        case hobbies
        case howHear = "how_hear"
    }

    init(email: String,
         password: String,
         passwordConfirmation: String,
         nickName: String,
         realName: String,
         birthDate: Date,
         gender: Gender,
         location: Location,
         phone: String?,
         hobbies: [Hobby],
         howHear: HowHear) {

        self.email = email
        self.password = password
        self.passwordConfirmation = passwordConfirmation
        self.nickName = nickName
        self.realName = realName
        self.birthDate = birthDate
        self.gender = gender
        self.location = location
        self.phone = phone
        self.hobbies = hobbies
        self.howHear = howHear
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ModelSupport.sharedInstance.dateFormatter

        try container.encode(self.email, forKey: .email)
        try container.encode(self.password, forKey: .password)
        try container.encode(self.passwordConfirmation, forKey: .passwordConfirmation)
        try container.encode(self.nickName, forKey: .nickName)
        try container.encode(self.nickName, forKey: .nickName)
        try container.encode(self.realName, forKey: .realName)
        try container.encodeAsString(self.birthDate, forKey: .birthDate, dateFormatter: dateFormatter)
        try container.encode(self.gender.rawValue, forKey: .gender)
        if let phone = self.phone, phone.isEmpty == false {
            try container.encode(phone, forKey: .phone)
        }
        try container.encode(self.location, forKey: .location)
        try container.encode(self.hobbies, forKey: .hobbies)
        try container.encode(self.howHear.id, forKey: .howHear)

    }

}
