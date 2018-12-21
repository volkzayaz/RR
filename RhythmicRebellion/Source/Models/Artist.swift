//
//  Artist.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/28/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxDataSources

public struct Artist: Codable {

    let id: String
    let name: String
    let subDomain: String?
    let likesCount: Int?
    let urlString: String?
    let addons: [Addon]?
    let publishDate: Date?

    let profileImage: Image?
    
    var url: URL? {
        guard let urlString = self.urlString, let urlComponents = URLComponents(string: urlString) else { return nil }

        var updatedURLComponents = urlComponents
        if updatedURLComponents.scheme == nil { updatedURLComponents.scheme = "https"}

        return updatedURLComponents.url
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case subDomain = "sub_domain"
        case likesCount = "likes_count"
        case urlString = "url"
        case addons = "audio_add_ons"
        case publishDate = "publish_date"
        case profileImage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        self.subDomain = try container.decodeIfPresent(String.self, forKey: .subDomain)
        self.likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount)

        self.urlString = try container.decodeIfPresent(String.self, forKey: .urlString)

        self.addons = try container.decodeIfPresent([Addon].self, forKey: .addons)

        self.publishDate = try container.decodeAsDate(String.self, forKey: .publishDate, dateFormatter: dateTimeFormatter)
        
        profileImage = try container.decodeIfPresent(Image.self, forKey: .profileImage)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)

        try container.encode(self.subDomain, forKey: .subDomain)
        try container.encode(self.likesCount, forKey: .likesCount)

        try container.encode(self.urlString, forKey: .urlString)

        try container.encode(self.addons, forKey: .addons)

        try container.encodeAsString(self.publishDate, forKey: .publishDate, dateFormatter: dateTimeFormatter)
    }

    
}

extension Artist: IdentifiableType, Equatable {
    
    public var identity : String { return id }
    
    public static func ==(lhs: Artist, rhs: Artist) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.urlString == rhs.urlString
    }
    
}
