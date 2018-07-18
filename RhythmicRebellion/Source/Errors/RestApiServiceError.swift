//
//  RestApiServiceError.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public enum RestApiServiceError: ErrorsGroup {
    case unexpectedResponse
}

extension RestApiServiceError {

    public var description: String {
        switch self {
        case .unexpectedResponse: return NSLocalizedString("Unexpected response", comment: "Unexpected response")
        }
    }
}

extension AppError {

    public init(_ restApiServiceError: RestApiServiceError,
                reason: String = "",
                file: String = #file,
                line: UInt = #line,
                function: String = #function) {

        self.init(
            restApiServiceError.description + " \(reason)",
            source: restApiServiceError,
            file: file,
            line: line,
            function: function
        )
    }
}
