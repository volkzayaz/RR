//
//  User.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

//"data": {
//    "_id": "5b36478e9caba4003a6a3252",
//    "ws_token": "5ce24a949e95cd5cc2356e51d0691209d7de08c4f68b4b35ff8d4d414157e968",
//    "updated_at": "2018-06-29T14:51:58+0000",
//    "created_at": "2018-06-29T14:51:58+0000",
//    "login_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1YjM2NDc4ZTljYWJhNDAwM2E2YTMyNTIiLCJndWVzdCI6dHJ1ZSwiaXNzIjoiaHR0cDovL3BsYXllci1uZ3J4Mi5hcGkucmViZWxsaW9ucmV0YWlsc2l0ZS5jb20vYXBpL2Zhbi91c2VyIiwiaWF0IjoxNTMwMjgzOTE4LCJleHAiOjE1MzExNDc5MTgsIm5iZiI6MTUzMDI4MzkxOCwianRpIjoiSTh3V0E0QzJyMUV3RFBHUiJ9._NFNWImTpPNeaZe2qmBsxKrYM9XM8ClS869P2fWCKuY",
//    "guest": true
//}


public protocol User: Decodable {
    var isGuest: Bool { get }
    var wsToken: String { get }
}

//func == (lhs: User, rhs: User) -> Bool {
//    guard type(of: lhs) == type(of: rhs) else { return false }
//    return lhs.wsToken == rhs.wsToken
//}


struct GuestUser: User {

    let isGuest: Bool
    let wsToken: String

    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
        case isGuest = "guest"
    }
}

extension GuestUser: Equatable {
    static func == (lhs: GuestUser, rhs: GuestUser) -> Bool {
        return lhs.wsToken == rhs.wsToken
    }
}

struct UserProfile: Decodable {

    let id: Int
    let email: String
    let nickName: String
    let firstName: String
    let gender: Gender?
    let birthDate: Date?
//    let location: Location
    let phone: String?
    let hobbies: [Hobby]
    let howHearId: Int
    var listeningSettings: ListeningSettings

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case email
        case nickName = "nick_name"
        case firstName = "real_name"
        case gender
        case birthDate = "birth_date"
//        case location
        case phone
        case hobbies
        case howHearId = "how_hear"
        case listeningSettings = "listening_settings"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ModelSupport.sharedInstance.dateFormatter


        self.id = try container.decode(Int.self, forKey: .id)
        self.email = try container.decode(String.self, forKey: .email)
        self.nickName = try container.decode(String.self, forKey: .nickName)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        if let genderRowValue = try? container.decode(Int.self, forKey: .gender) {
            self.gender = Gender(rawValue: genderRowValue)
        } else {
            self.gender = nil
        }

        self.birthDate = try container.decodeAsDate(String.self, forKey: .birthDate, dateFormatter: dateFormatter)
        //        self.location = try container.decode(Location.self, forKey: .location)
        self.phone = try? container.decode(String.self, forKey: .phone)
        self.hobbies = try container.decode([Hobby].self, forKey: .hobbies)
        self.howHearId = try container.decode(Int.self, forKey: .howHearId)

        self.listeningSettings = try container.decode(ListeningSettings.self, forKey: .listeningSettings)
    }
}

struct FanUser: User {

    let profile: UserProfile
    let wsToken: String
    let isGuest: Bool = false

    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
    }

    init(from decoder: Decoder) throws {
        self.profile = try UserProfile(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wsToken = try container.decode(String.self, forKey: .wsToken)
    }
    
}

extension FanUser: Equatable {
    static func == (lhs: FanUser, rhs: FanUser) -> Bool {
        guard lhs.profile.id == rhs.profile.id, lhs.wsToken == rhs.wsToken else { return false }
        return true
    }
}





