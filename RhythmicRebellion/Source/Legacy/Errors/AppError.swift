//
//  AppError.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol ErrorsGroup { }

public struct AppError: LocalizedError {

    public var errorDescription: String?
    public var localizedDescription: String { return errorDescription! }

    public let file: String
    public let line: UInt
    public let function: String

    internal let source: ErrorsGroup?

    internal init(_ text: String, source: ErrorsGroup? = nil, file: String = #file, line: UInt = #line, function: String = #function) {
        self.errorDescription = text
        self.file = file
        self.line = line
        self.function = function
        self.source = source
    }

    public func loggerDescription() -> String {
        let path = (file as NSString).lastPathComponent
        return "\(errorDescription ?? "") [error source: \(path):\(line) at \(function)])"
    }
}
