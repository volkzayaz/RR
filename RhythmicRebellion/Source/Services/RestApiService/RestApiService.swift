//
//  RestApiService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum RestApiServiceResult<T> {
    case success(T)
    case failure(Error)
}

class RestApiService {

    let serverURL: URL

    public init(serverURL: URL) {
        self.serverURL = serverURL
    }

    private func makeURL(with path: String) -> URL? {
        var componets    = URLComponents(url: self.serverURL, resolvingAgainstBaseURL: true)
        componets?.path  = "/api/" + path

        return componets?.url
    }

    // MARK: - User

    func fanUser(completion: @escaping (RestApiServiceResult<User>) -> Void) {

        guard let fanUserURL = self.makeURL(with: "fan/user") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanUserURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanUserResponse>) in

                guard dataResponse.error == nil else { completion(.failure(dataResponse.error!)); return }
                guard let user = dataResponse.value?.user else { completion(.failure(AppError(.unexpectedResponse))); return }

                completion(.success(user))
        }
    }

    func fanLogin(email: String, password: String, completion: @escaping (RestApiServiceResult<User>) -> Void) {

        guard let fanLoginURL = self.makeURL(with: "fan/login") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        let parameters: Parameters = ["email" : email, "password" : password]

        Alamofire.request(fanLoginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanLoginResponse>) in
                guard dataResponse.error == nil else { completion(.failure(dataResponse.error!)); return }
                guard let user = dataResponse.value?.user else { completion(.failure(AppError(.unexpectedResponse))); return }

                completion(.success(user))
        }
    }

    func fanLogout(completion: @escaping (RestApiServiceResult<User>) -> Void) {
        guard let fanLogoutURL = self.makeURL(with: "fan/logout") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanLogoutURL, method: .post, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanUserResponse>) in
                guard dataResponse.error == nil else { completion(.failure(dataResponse.error!)); return }
                guard let user = dataResponse.value?.user else { completion(.failure(AppError(.unexpectedResponse))); return }

                completion(.success(user))
        }

    }

    // MARK: - Player

    func audioAddons(for trackIds: [Int], completion: @escaping (RestApiServiceResult<[Int : [Addon]]>) -> Void) {
        guard let addonsForTracksURL = self.makeURL(with: "player/audio-add-ons-for-tracks") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json"]
        let jsonQuery = ["filters" : ["record_id" : ["in" : trackIds]]]

        do {
            let jsonQueryData = try JSONSerialization.data(withJSONObject: jsonQuery)
            guard let jsonQueryString = String(data: jsonQueryData, encoding: .utf8) else { return }

            let parameters: Parameters = ["jsonQuery" : jsonQueryString]

            Alamofire.request(addonsForTracksURL, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
                .validate()
                .restApiResponse { (dataResponse: DataResponse<AddonsForTracksResponse>) in

                    guard dataResponse.error == nil else { completion(.failure(dataResponse.error!)); return }

                    completion(.success(dataResponse.value!.value))
            }

        } catch (let error) {
            completion(.failure(error))
        }
    }
}
