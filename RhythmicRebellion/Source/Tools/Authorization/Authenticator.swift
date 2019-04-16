//
//  Authenticator.swift
//   
//
//  Created by Vlad Soroka on 2/12/16.
//  Copyright © 2016   All rights reserved.
//

import RxSwift



/**
 *  @discussion - data that can be used for authentication in    
 */
enum AuthenticationData {
    
    struct Registration {
        
        let name: String
        let password: String
        let email: String
    }
    
    struct ExternalProvider {
        enum Rout {
            case facebook
        }; let rout: Rout
        
        let accessToken: String
        
        let birthdate: Date?
        let howHear: Int?
        let country: Country?
    }
    
    case external(data: ExternalProvider)
    
}

protocol Authenticator {
    
    func authenticateUser(onController controller: UIViewController) -> Observable<AuthenticationData>
    
}
