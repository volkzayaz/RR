//
//  Float+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension Float {
    func timeString() -> String {

        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]

        let components = NSDateComponents()
        components.second = Int(max(0.0, self))

        return formatter.string(from: components as DateComponents) ?? "00:00"
    }
}
