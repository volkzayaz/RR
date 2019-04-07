//
//  RxResponse.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 1/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct AddonsForTracksResponse: Codable {
    
    let trackAddons: [String : [Addon]]
    
    enum CodingKeys: String, CodingKey {
        case trackAddons = "data"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.trackAddons = try container.decode([String : [Addon]].self, forKey: .trackAddons)
        } catch (let error) {
            guard let emptyAddons = try? container.decodeIfPresent([Addon].self, forKey: .trackAddons),
                emptyAddons?.isEmpty ?? false else { throw error }
            
            self.trackAddons = [:]
        }
    }
}
