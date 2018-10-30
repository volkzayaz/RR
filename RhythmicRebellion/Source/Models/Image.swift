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

    let uuid: String?
    let links: [ImageLinkType.RawValue: ImageLink]

    enum CodingKeys: String, CodingKey {
        case uuid
        case links
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.uuid = try container.decodeIfPresent(String.self, forKey: .uuid)
        self.links = try container.decode([ImageLinkType.RawValue: ImageLink].self, forKey: .links)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.links, forKey: .links)
    }
}

extension Image: Equatable {
    static func == (lhs: Image, rhs: Image) -> Bool {
        guard let lhsuuid = lhs.uuid, let rhsuuid = rhs.uuid else { return false }
        return lhsuuid == rhsuuid
    }
}

//extension Image: Hashable {
//
//    public var hashValue: Int { return self.uuid.hashValue }
//}

