//
//  FakeNetwork.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Alamofire
import Mocker

@testable import RhythmicRebellion

class FakeNetwork: Network {
    
    init() {
        
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        super.init(sm: SessionManager(configuration: configuration))
        
    }
}
