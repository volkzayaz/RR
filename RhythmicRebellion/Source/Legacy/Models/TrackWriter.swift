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
    let publishDate: Date?

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
        case publishDate = "publish_date"
    }
    
    init(withID id: String,
         name: String,
         urlString: String? = nil,
         publishDate: Date? = nil) {
        
        self.id = id
        self.name = name
        self.urlString = urlString
        self.publishDate = publishDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        self.urlString = try container.decodeIfPresent(String.self, forKey: .urlString)
        self.publishDate = try container.decodeAsDate(String.self, forKey: .publishDate, dateFormatter: dateTimeFormatter)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)

        try container.encode(self.urlString, forKey: .urlString)
        try container.encodeAsString(self.publishDate, forKey: .publishDate, dateFormatter: dateTimeFormatter)
    }
}
