//
//  FacebookAuthenticator.swift
//   
//
//  Created by Vlad Soroka on 2/12/16.
//  Copyright © 2016   All rights reserved.
//

import Foundation
import RxSwift
import SafariServices
import Alamofire

extension FacebookAuthenticator : Authenticator {

    func authenticateUser(onController controller: UIViewController) -> Observable<AuthenticationData> {
        
        let fb = Facebook()
        fb.scopes = ["public_profile", "email", "user_birthday"]
        
        Simplicity.safariLogin(fb, safariDelegate: self) {
            [unowned self] maybeToken, maybeError in
            
            guard maybeError == nil else {
                
                if maybeError!.localizedDescription == "Permissions error" {
                    self.outcome.onError(RRError.userCanceled)
                    return
                }
                
                self.outcome.onError(RRError.generic(message: maybeError!.localizedDescription))
                
                return;
            }
            
            guard let token = maybeToken else {
                fatalError("Simplicity for facebook returned neither token nor error")
            }
            
            self.outcome.onNext(token)
            
        }
        
        return outcome.asObservable()
            .skip(1)
            .take(1)
            .map { token in
                
                return .external(data: AuthenticationData.ExternalProvider(rout: .facebook,
                                                                           accessToken: token, birthdate: nil, howHear: nil, country: nil))
            }

    }
    
}

class FacebookAuthenticator : NSObject {
    
    fileprivate let outcome: BehaviorSubject<String> = BehaviorSubject(value: "")
    
}

extension FacebookAuthenticator : SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        outcome.onError(RRError.userCanceled)
    }
    
}
