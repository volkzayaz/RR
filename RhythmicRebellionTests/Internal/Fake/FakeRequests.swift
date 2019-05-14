//
//  FakeRequests.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Mocker

struct FakeRequests {
    
    static func registerMockRequestAddons(with url: URL) {
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            Mock.HTTPMethod.get : FakeData.addon
            ]).register()
    }
    
    static func registerMockRequestArtist(with url: URL) {
        Mock(url: url, dataType: .json, statusCode: 200, data: [
            Mock.HTTPMethod.get : FakeData.artist
            ]).register()
    }
}
