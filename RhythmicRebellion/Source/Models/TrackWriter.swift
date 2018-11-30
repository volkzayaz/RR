//
//  TrackWriter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct TrackWriter: Codable {

    let id: String
    let name: String
    let urlString: String?

    var url: URL? {
        guard let urlString = self.urlString, let urlComponents = URLComponents(string: urlString) else { return nil }

        var updatedURLComponents = urlComponents
        if updatedURLComponents.scheme == nil { updatedURLComponents.scheme = "https"}

        return updatedURLComponents.url
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case urlString = "url"
    }
}
