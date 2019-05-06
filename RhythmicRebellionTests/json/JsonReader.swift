//
//  jsonReader.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class JsonReader {
    
    static func readData(withName name: String) throws -> Data {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            fatalError("UnitTestData.json not found")
        }
        
        return try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
    }
    
    static func readJson(withName name: String) throws -> Dictionary<String, AnyObject> {
        
        let data = try self.readData(withName: name)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        return jsonResult as! Dictionary<String, AnyObject>
    }
}

