//
//  AlbumRequest.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/10/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum AlbumRequest: BaseNetworkRouter {

    case details(x: Int)
    case downloadLink(album: Album)
    
}

extension AlbumRequest {
    
    func asURLRequest() throws -> URLRequest {
        
        switch self {
            
        case .downloadLink(let album):
            
            return anonymousRequest(method: .get,
                                    path: "fan/store/order/download-link/album/\(album.id)")
            
        case .details(let x):
            
            return personilisedRequest(method: .get,
                                       path: "fan/artist/album/\(x)")
            
        }
        
    }
    
}
