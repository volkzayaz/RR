//
//  ConfigRequest.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/1/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum ConfigRequest: BaseNetworkRouter {
    
    case player
    case user
    
    case genres
    case countries
    case regions(for: Country)
    case cities(for: Region)
    case location(for: Country, zip: String)
    
}

extension ConfigRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .player:
            return anonymousRequest(method: .get,
                                    path: "player/config")
            
        case .user:
            return anonymousRequest(method: .get,
                                    path: "config")
         
        case .genres:
            return anonymousRequest(method: .get,
                                    path: "song-characteristics/list-genre")
            
        case .countries:
            return anonymousRequest(method: .get,
                                    path: "gis/country")
            
        case .regions(let country):
            return anonymousRequest(method: .get,
                                    path: "gis/country/" + country.code + "/state")
            
        case .cities(let region):
            return anonymousRequest(method: .get,
                                    path: "gis/country/" + region.countryCode + "/state/" + String(region.id))
            

        case .location(let country, let zip):
            return anonymousRequest(method: .get,
                                    path: "gis/location",
                                    params: ["country_code": country.code,
                                             "postal_code": zip],
                                    encoding: URLEncoding.queryString)
            
        }
    }
}
