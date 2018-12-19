//
//  FollowingRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum ArtistsFollowingRouter: BaseNetworkRouter {
    case list
}

extension ArtistsFollowingRouter {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .list:
            return anonymousRequest(method: .get,
                                    path: "fan/artist-follow")
        
        }
        
    }
    
}
