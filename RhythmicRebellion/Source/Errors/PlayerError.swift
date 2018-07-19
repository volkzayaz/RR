//
//  PlayerError.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public enum PlayerError: ErrorsGroup {
    case notInitialized
    case prepareAddons
}

extension PlayerError {

    public var description: String {
        switch self {
        case .notInitialized: return NSLocalizedString("Player has not initialized", comment: "Player has not initialized")
        case .prepareAddons: return NSLocalizedString("Unable to prepare Addons for Track", comment: "Unable to prepare Addons for Track")
        }
    }
}

extension AppError {

    public init(_ playerError: PlayerError,
                reason: String = "",
                file: String = #file,
                line: UInt = #line,
                function: String = #function) {

        self.init(
            playerError.description + " \(reason)",
            source: playerError,
            file: file,
            line: line,
            function: function
        )
    }
}
