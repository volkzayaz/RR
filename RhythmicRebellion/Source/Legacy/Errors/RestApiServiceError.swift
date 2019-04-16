//
//  RestApiServiceError.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public enum RestApiServiceError: ErrorsGroup {
    case unauthorized
    case unexpectedResponse
    case serverError(String, [String : [String]])
}

extension RestApiServiceError {

    public var description: String {
        switch self {
        case .unauthorized: return NSLocalizedString("Unauthorized.", comment: "Unauthorized request for instance")
        case .unexpectedResponse: return NSLocalizedString("Unexpected response", comment: "Unexpected response")
        case .serverError(let message, let errors): return errors.first?.value.first ?? message
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

enum RRError: Error {
    
    case userCanceled
    
    case generic(message: String)
    
}
