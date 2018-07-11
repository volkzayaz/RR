//
//  RestApiService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum RestApiServiceResult<T: Decodable> {
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

    func fanUser(completion: @escaping (User?) -> Void) {

        guard let fanUserURL = self.makeURL(with: "fan/user") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanUserURL, method: .get, headers: headers).validate().response { (response) in
            guard let responseData = response.data else { completion(nil); return }

            do {
                let user = try JSONDecoder().decode(User.self, from: responseData)
                completion(user)
            } catch (let error) {
                 print(error.localizedDescription)
                completion(nil)
            }
        }
    }

    func fanLogin(email: String, password: String, completion: @escaping (User?) -> Void) {

        guard let fanLoginURL = self.makeURL(with: "fan/login") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        let parameters: Parameters = ["email" : email, "password" : password]

        Alamofire.request(fanLoginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).validate().response { (response) in
            guard let responseData = response.data else { completion(nil); return }

            do {
                let user = try JSONDecoder().decode(User.self, from: responseData)
                completion(user)
            } catch (let error) {
                print(error.localizedDescription)
                completion(nil)
            }
        }
    }

    // MARK - Player -

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
                .restApiResponse { (dataResponse: DataResponse<AddonsForTracks>) in

                    guard dataResponse.error == nil else { completion(.failure(dataResponse.error!)); return }

                    completion(.success(dataResponse.value!.value))
            }

        } catch (let error) {
            completion(.failure(error))
        }
    }
}
