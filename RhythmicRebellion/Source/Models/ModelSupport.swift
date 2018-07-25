//
//  ModelSupport.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

class ModelSupport {
    static let sharedInstance = ModelSupport()

    lazy var dateFormatter: DateFormatter = {
        let dateTimeFormattre = DateFormatter()

        dateTimeFormattre.timeZone = TimeZone(secondsFromGMT: 0)
        dateTimeFormattre.dateFormat = "yyyy-MM-dd"

        return dateTimeFormattre
    }()

    lazy private var dateTimeFormattre: DateFormatter = {
        let dateTimeFormattre = DateFormatter()

        dateTimeFormattre.timeZone = TimeZone(secondsFromGMT: 0)
        dateTimeFormattre.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        return dateTimeFormattre
    }()

    func date(from string: String) -> Date? {

        var date = self.dateTimeFormattre.date(from: string)
        if date == nil { date = self.dateFormatter.date(from: string) }

        return date
    }

    func string(from date: Date) -> String {
        return dateTimeFormattre.string(from: date)
    }
}
