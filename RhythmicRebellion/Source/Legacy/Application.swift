//
//  Application.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Reachability
import Alamofire
import RxSwift

class Application {

    let restApiService: RestApiService
    
    init?() {
        guard let restApiService = RestApiService(serverURI: URI.restApiService, originURI: URI.origin) else { return nil }
        
        self.restApiService = restApiService
        
        initAppState()
        
    }

}
