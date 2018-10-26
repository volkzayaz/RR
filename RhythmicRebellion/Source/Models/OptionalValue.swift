//
//  OptionalValue.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public enum OptionalValue<T: Codable>: Codable {
    case null
    case value(T)

    var isNull: Bool {
        switch self {
        case .null: return true
        case .value: return false
        }
    }

    var value: T? {
        switch self {
        case .null: return nil
        case .value(let value): return value
        }
    }

    public init(_ value: T?) {
        self = value.map(OptionalValue.value) ?? .null
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        guard container.decodeNil() == false else { self = .null; return }

        self = .value(try container.decode(T.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case let .value(value): try container.encode(value)
        }
    }
}
