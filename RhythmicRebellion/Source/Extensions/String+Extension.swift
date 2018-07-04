//
//  String+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

extension String {

    public init(randomWithLength length: Int, allowedCharacters: AllowedCharacters) {
        let allowedCharsString: String = {
            switch allowedCharacters {
            case .numeric:
                return "0123456789"

            case .alphabetic:
                return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

            case .alphaNumeric:
                return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
            }
        }()

        self.init(allowedCharsString.random(with: length))
    }

    public func random(with length: Int) -> String {
        guard !isEmpty else { return "" }

        let charactersCount = UInt32(self.count)
        var sampleElements = String()
        for _ in 0 ..< length {
            let randomNum = Int(arc4random_uniform(charactersCount))
            let randomIndex = self.index(self.startIndex, offsetBy: randomNum)
            sampleElements.append(self[randomIndex])
        }

        return sampleElements
    }
}

extension String {

    public enum AllowedCharacters {
        case numeric
        case alphabetic
        case alphaNumeric
    }
}

