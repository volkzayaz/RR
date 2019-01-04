//
//  FollowingRouter.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum ArtistsFollowingRequest: BaseNetworkRouter {
    case list
    
    case follow(artist: Artist)
    case unfollow(artist: Artist)
    
}

extension ArtistsFollowingRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .list:
            return anonymousRequest(method: .get,
                                    path: "fan/artist-follow")
        
        case .follow(let artist):
            return anonymousRequest(method: .post,
                                    path: "fan/artist-follow/\(artist.id)")
            
        case .unfollow(let artist):
            return anonymousRequest(method: .delete,
                                    path: "fan/artist-follow/\(artist.id)")
            
        }
        
    }
    
}
