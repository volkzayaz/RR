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
    case large
    case xlarge
    case medium
    case original
    case preload
    case small
    case xsmall

    case thumb
    case big
}

struct ImageLink: Codable {

    enum PathType {
        case url(String)
        case base64(String)

        var string: String {
            switch self {
            case .url(let urlString): return urlString
            case .base64(let base64String): return base64String
            }
        }
    }

    let path: PathType
    let width: Float
    let height: Float

    var size: CGSize { return CGSize(width: CGFloat(width), height: CGFloat(height)) }

    enum CodingKeys: String, CodingKey {
        case path
        case width
        case height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let pathString = try container.decode(String.self, forKey: .path)
        if pathString.starts(with: "data") {
            self.path = .base64(pathString)
        } else {
            self.path = .url(pathString)
        }

        var tempWidth: Float = 0.0
        var tempHeight: Float = 0.0
        do {
            tempWidth = try container.decode(Float.self, forKey: .width)
            tempHeight = try container.decode(Float.self, forKey: .height)
        } catch {
            tempWidth = Float(try container.decode(String.self, forKey: .width)) ?? 0.0
            tempHeight = Float(try container.decode(String.self, forKey: .height)) ?? 0.0
        }

        self.width = tempWidth
        self.height = tempHeight
        
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.path.string, forKey: .path)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
    }
}

struct Image: Codable {

    let uuid: String
    let links: [ImageLinkType.RawValue: ImageLink]

    enum CodingKeys: String, CodingKey {
        case uuid
        case links
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.uuid = try container.decode(String.self, forKey: .uuid)
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
        return lhs.uuid == rhs.uuid
    }
}

extension Image: Hashable {
    public var hashValue: Int { return self.uuid.hashValue }
}

