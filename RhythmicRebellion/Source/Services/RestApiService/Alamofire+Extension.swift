//
//  Alamofire+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

extension Request {
    /// Returns a RestApiResponse object contained in a result type constructed from the response data using `JSONDecoder`
    ///
    /// - parameter response: The response from the server.
    /// - parameter data:     The data returned from the server.
    /// - parameter error:    The error already encountered if it exists.
    ///
    /// - returns: The result data type.
    public static func serializeRestApiResponse<T: RestApiResponse>(
        response: HTTPURLResponse?,
        data: Data?,
        error: Error?)
        -> Result<T>
    {
        guard error == nil else {
            guard let errorData = data, errorData.count > 0,
                let restApiResponse = try? JSONDecoder().decode(ErrorResponse.self, from: errorData) else { return .failure(error!) }

            return .failure(AppError(.serverError(restApiResponse.message, restApiResponse.errors)))
        }

        if let response = response, emptyDataStatusCodes.contains(response.statusCode) {

            guard T.self is EmptyRestApiResponse.Type else {
                return .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
            }

            let emptyRestApiResponseType = T.self as! EmptyRestApiResponse.Type
            let emptyResponse = emptyRestApiResponseType.init() as! T

            return .success(emptyResponse)
        }

        guard let validData = data, validData.count > 0 else {
            return .failure(AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
        }

        do {
            let restApiResponse = try JSONDecoder().decode(T.self, from: validData)
            return .success(restApiResponse)
        } catch {
            return .failure(AFError.responseSerializationFailed(reason: .jsonSerializationFailed(error: error)))
        }
    }
}


extension DataRequest {
    /// Creates a response serializer that returns a RestApiResponse object result type constructed from the response data using
    ///
    /// - returns: A RestApiResponse object response serializer.
    public static func restApiResponseSerializer<T: RestApiResponse>()
        -> DataResponseSerializer<T>
    {
        return DataResponseSerializer { _, response, data, error in
            return Request.serializeRestApiResponse(response: response, data: data, error: error)
        }
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished.
    ///
    /// - returns: The request.
    @discardableResult
    public func restApiResponse<T: RestApiResponse>(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<T>) -> Void)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.restApiResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}

/// A set of HTTP response status code that do not contain response data.
private let emptyDataStatusCodes: Set<Int> = [204, 205]
