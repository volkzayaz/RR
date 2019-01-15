//
//  TimeInterval+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension TimeInterval {
    // builds string in app's labels format 00:00
    func stringFormatted() -> String {
        let interval = Int(self.rounded(.down))
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
