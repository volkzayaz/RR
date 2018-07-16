//
//  WebSocketServiceError.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

public enum WebSocketServiceError: ErrorsGroup {
    case unauthorized
    case offline
    case custom(Error)
}

extension WebSocketServiceError {

    public var description: String {
        switch self {
        case .unauthorized: return NSLocalizedString("Unauthorized.", comment: "Unauthorized request for instance")
        case .offline: return NSLocalizedString("The Internet connection appears to be offline.", comment: "")
        case .custom(let error): return error.localizedDescription
        }
    }
}

extension AppError {

    public init(_ webSocketServiceError: WebSocketServiceError,
                reason: String = "",
                file: String = #file,
                line: UInt = #line,
                function: String = #function) {

        self.init(
            webSocketServiceError.description + " \(reason)",
            source: webSocketServiceError,
            file: file,
            line: line,
            function: function
        )
    }
}
