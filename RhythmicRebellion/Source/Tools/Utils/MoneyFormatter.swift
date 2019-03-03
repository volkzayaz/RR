//
//  TrackPriceFormatter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/8/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class MoneyFormatter: NumberFormatter {

    override init() {
        super.init()
        self.numberStyle = .currency
        self.minimumFractionDigits = 2
        self.maximumFractionDigits = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func string(from money: Money) -> String? {
        self.currencySymbol = money.currency.symbol
        return self.string(from: money.amount as NSDecimalNumber)
    }
}
