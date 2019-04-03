//
//  PlaylistRequest.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/3/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum PlaylistRequest: BaseNetworkRouter {
    
    case create(name: String) ///returns FanPlaylist
    case delete(playlist: FanPlaylist)/// Void
    
}

extension PlaylistRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .create(let name):
            return anonymousRequest(method: .post,
                                    path: "fan/playlist",
                                    params: ["name": name])
            
            
        case .delete(let playlist):
            return anonymousRequest(method: .delete,
                                    path: "fan/playlist/\(playlist.id)")
            
            
        }
    }
}

