//
//  RestApiRequestPayloads.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/25/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct UserProfilePayload: Encodable {

    let userProfile: UserProfile

    init(with userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    enum CodingKeys: String, CodingKey {
        case nickname = "nick_name"
        case firstName = "real_name"
        case gender
        case birthDate = "birth_date"
        case location
        case phone
        case hobbies
        case genres
        case language
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ModelSupport.sharedInstance.dateFormatter

        try container.encode(self.userProfile.firstName, forKey: .firstName)
        try container.encode(self.userProfile.nickname, forKey: .nickname)
        try container.encodeAsString(self.userProfile.birthDate, forKey: .birthDate, dateFormatter: dateFormatter)
        try container.encode(self.userProfile.gender?.rawValue ?? 0, forKey: .gender)
        try container.encode(self.userProfile.phone, forKey: .phone)
        try container.encode(self.userProfile.location, forKey: .location)
        try container.encode(self.userProfile.hobbies, forKey: .hobbies)
        try container.encode(self.userProfile.genres, forKey: .genres)
        try container.encode(self.userProfile.language, forKey: .language)
    }
}

struct ListeningSettingsPayload: Encodable {

    let listeningSettings: ListeningSettings

    enum CodingKeys: String, CodingKey {
        case listeningSettings = "listening_settings"
    }

    init(with listeningSettings: ListeningSettings) {
        self.listeningSettings = listeningSettings
    }

}

struct RegisterData: Encodable {

    let email: String
    let password: String
    var passwordConfirmation: String
    var nickname: String
    var realName: String
    var birthDate: Date
    var gender: Gender?
    var location: ProfileLocation
    var phone: String?
    var hobbies: [Hobby]
    var howHear: HowHear


    enum CodingKeys: String, CodingKey {
        case email
        case password
        case passwordConfirmation = "password_confirmation"
        case nickname = "nick_name"
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
         nickname: String,
         realName: String,
         birthDate: Date,
         gender: Gender?,
         location: ProfileLocation,
         phone: String?,
         hobbies: [Hobby],
         howHear: HowHear) {

        self.email = email
        self.password = password
        self.passwordConfirmation = passwordConfirmation
        self.nickname = nickname
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
        try container.encode(self.nickname, forKey: .nickname)
        try container.encode(self.realName, forKey: .realName)
        try container.encodeAsString(self.birthDate, forKey: .birthDate, dateFormatter: dateFormatter)
        
        try container.encode(self.gender?.rawValue ?? 0, forKey: .gender)
        
        if let phone = self.phone, phone.isEmpty == false {
            try container.encode(phone, forKey: .phone)
        }
        try container.encode(self.location, forKey: .location)
        try container.encode(self.hobbies, forKey: .hobbies)
        try container.encode(self.howHear.id, forKey: .howHear)

    }

}

