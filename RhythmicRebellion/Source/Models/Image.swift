//
//  Image.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import CoreGraphics

enum ImageLinkType: String {
    case thumb
    case big
}

struct ImageLink: Codable {

    let urlString: String
    let width: Float
    let height: Float

    var size: CGSize { return CGSize(width: CGFloat(width), height: CGFloat(height)) }

    enum CodingKeys: String, CodingKey {
        case urlString = "path"
        case width
        case height
    }
}

struct Image: Codable {

    let id: Int
    let ownerId: String
    let title: String
    let originalName: String
    let links: [ImageLinkType.RawValue: ImageLink]
//    "shared_to_websites": [ "d370474b-be80-4ddf-bbc5-c45c94c13248" ],
    let isActive: Bool
    let createdDate: Date?
    let updatedDate: Date?
//    "file_size": 1027245,
//    "pivot": {
//    "model_id": 109,
//    "image_id": 109,
//    "model_type": "record"
//     }

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case originalName = "original_name"
        case links
        case isActive = "is_active"
        case createdDate = "created_at"
        case updatedDate = "updated_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.title = try container.decode(String.self, forKey: .title)
        self.originalName = try container.decode(String.self, forKey: .originalName)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)

        self.links = try container.decode([ImageLinkType.RawValue: ImageLink].self, forKey: .links)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        self.createdDate = try container.decodeAsDate(String.self, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        self.updatedDate = try container.decodeAsDate(String.self, forKey: .updatedDate, dateFormatter: dateTimeFormatter)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.id, forKey: .id)
        try container.encode(self.ownerId, forKey: .ownerId)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.originalName, forKey: .originalName)
        try container.encode(self.isActive, forKey: .isActive)

        try container.encode(self.links, forKey: .links)

        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre
        try container.encodeAsString(self.createdDate, forKey: .createdDate, dateFormatter: dateTimeFormatter)
        try container.encodeAsString(self.updatedDate, forKey: .updatedDate, dateFormatter: dateTimeFormatter)
    }
}

extension Image: Equatable {
    static func == (lhs: Image, rhs: Image) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Image: Hashable {

    public var hashValue: Int { return self.id }
}

