//
//  Price.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/5/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum Currency {
    case USD

    var symbol: String {
        switch self {
        case .USD: return "$"
        }
    }
}

struct Money {

    let value: Decimal
    let currency: Currency

    var amount: Decimal {
        var roundedValue: Decimal = self.value
        var value = self.value
        NSDecimalRound(&roundedValue, &value, 2, .down)
        return roundedValue
    }
}
