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

    public init(serverURL: URL) {
        self.serverURL = serverURL
    }

    private func makeURL(with path: String) -> URL? {
        var componets    = URLComponents(url: self.serverURL, resolvingAgainstBaseURL: true)
        componets?.path  = "/api/" + path

        return componets?.url
    }

    func getFanUser(completion: @escaping (User?) -> Void) {

        guard let fanUserURL = self.makeURL(with: "fan/user") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanUserURL, method: .get, headers: headers).validate().response { (response) in
            guard let responseData = response.data else { return }

            do {
                let user = try JSONDecoder().decode(User.self, from: responseData)
                completion(user)
            } catch (let error) {
                 print(error.localizedDescription)
                completion(nil)
            }
        }
    }
}
