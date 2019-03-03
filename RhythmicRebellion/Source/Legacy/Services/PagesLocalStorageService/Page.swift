//
//  Page.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct Page: Codable {

    let urlString: String

    var id: Int { return self.urlString.hashValue }
    var url: URL? { return URL(string: self.urlString) }

    enum CodingKeys: String, CodingKey {
        case urlString = "url"
    }

    init(url: URL) {
        self.urlString = url.absoluteString
    }
}

extension Page: Equatable {
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.urlString == rhs.urlString
    }
}

extension Page: Hashable {
    public var hashValue: Int { return self.urlString.hashValue }
}
