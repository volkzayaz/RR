//
//  CheckAddons.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct CheckAddons: Codable {

    enum Addons {
        case addonsStates([AddonState])
        case addonsIds([Int])
    }

    enum CodingKeys: String, CodingKey {
        case trackId = "srtId"
        case addons
    }

    let trackId: Int
    let addons: Addons

    enum CheckAddonsError:Error {
        case missingAddons
    }

    public init(trackId: Int, addonsStates: [AddonState]) {
        self.trackId = trackId
        self.addons = .addonsStates(addonsStates)
    }

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.trackId = try container.decode(Int.self, forKey: .trackId)

        if let addonsStates = try? container.decode([AddonState].self, forKey: .addons), addonsStates.isEmpty == false {
            self.addons = .addonsStates(addonsStates)
            return
        }

        if let addonsIds = try? container.decode([Int].self, forKey: .addons) {
            self.addons = .addonsIds(addonsIds)
            return
        }

        throw CheckAddonsError.missingAddons
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.trackId, forKey: .trackId)

        switch addons {
        case .addonsStates(let addonsStates): try container.encode(addonsStates, forKey: .addons)
        case .addonsIds(let addonsIds): try container.encode(addonsIds, forKey: .addons)
        }
    }
}


