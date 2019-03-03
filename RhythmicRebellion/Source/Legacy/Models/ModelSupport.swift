//
//  ModelSupport.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum Gender: Int {
    case male = 1
    case female = 2
}


public class ModelSupport {
    public static let sharedInstance = ModelSupport()

    var documentDirectoryURL: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    lazy var dateFormatter: DateFormatter = {
        let dateTimeFormattre = DateFormatter()

        dateTimeFormattre.locale = Locale(identifier: "en_US_POSIX")
        dateTimeFormattre.timeZone = TimeZone(secondsFromGMT: 0)
        dateTimeFormattre.dateFormat = "yyyy-MM-dd"

        return dateTimeFormattre
    }()

    lazy var dateTimeFormattre: DateFormatter = {
        let dateTimeFormattre = DateFormatter()

        dateTimeFormattre.locale = Locale(identifier: "en_US_POSIX")
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




extension KeyedDecodingContainerProtocol {

    public func decodeAsDate(_ type: String.Type, forKey key: Self.Key, dateFormatter: DateFormatter) throws -> Date? {
        guard let dateString = try? self.decode(type, forKey: key) else { return nil }
        return dateFormatter.date(from: dateString)
    }
}

extension KeyedEncodingContainerProtocol {

    public mutating func encodeAsString(_ value: Date?, forKey key: Self.Key, dateFormatter: DateFormatter) throws {
        var stringDate: String? = nil
        if let date = value { stringDate = dateFormatter.string(from: date) }
        try self.encode(stringDate, forKey: key)
    }
}
