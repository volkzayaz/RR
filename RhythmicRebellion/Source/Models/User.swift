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


protocol User: Decodable {
    var isGuest: Bool { get }
    var wsToken: String { get }
}


struct GuestUser: User {

    let isGuest: Bool
    let wsToken: String

    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
        case isGuest = "guest"
    }
}

struct FanUser: User {

    let id: Int
    let wsToken: String
    let isGuest: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case wsToken = "ws_token"
        case isGuest = "guest"
    }
}




