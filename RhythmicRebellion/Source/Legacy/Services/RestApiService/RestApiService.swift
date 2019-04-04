//
//  RestApiService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

class RestApiService {

    let serverURL: URL
    let originURI: String

    public init?(serverURI: String, originURI: String) {
        guard let serverURL = URL(string: serverURI) else { return nil }

        self.serverURL = serverURL
        self.originURI = originURI
    }

    private func makeURL(with path: String) -> URL? {
        var componets    = URLComponents(url: self.serverURL, resolvingAgainstBaseURL: true)
        componets?.path  = "/api/" + path

        return componets?.url
    }

    private func makeRequest<T: RestApiRequestPayload>(with url: URL,
                                                       httpMethod: HTTPMethod,
                                                       headers: HTTPHeaders? = nil,
                                                       requestPayload: T? = nil) throws -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue

        if let headers = headers {
            var allHTTPHeaderFields: HTTPHeaders = request.allHTTPHeaderFields ?? HTTPHeaders()
            allHTTPHeaderFields += headers
            request.allHTTPHeaderFields = allHTTPHeaderFields
        }

        if let requestPayload = requestPayload {
            let jsonData = try JSONEncoder().encode(requestPayload)
            request.httpBody = jsonData
        }

        return request
    }

    // MARK: - User

    
}
