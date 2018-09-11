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

    public init(serverURL: URL, originURI: String) {
        self.serverURL = serverURL
        self.originURI = originURI
    }

    private func makeURL(with path: String) -> URL? {
        var componets    = URLComponents(url: self.serverURL, resolvingAgainstBaseURL: true)
        componets?.path  = "/api/" + path

        return componets?.url
    }

    // MARK: - User

    func fanUser(completion: @escaping (Result<User>) -> Void) {

        guard let fanUserURL = self.makeURL(with: "fan/user") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanUserURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanUserResponse>) in

                switch dataResponse.result {
                case .success(let fanUserResponse): completion(.success(fanUserResponse.user))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanLogin(email: String, password: String, completion: @escaping (Result<User>) -> Void) {

        guard let fanLoginURL = self.makeURL(with: "fan/login") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        let parameters: Parameters = ["email" : email, "password" : password]

        Alamofire.request(fanLoginURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanLoginResponse>) in

                switch dataResponse.result {
                case .success(let fanLoginResponse): completion(.success(fanLoginResponse.user))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanLogout(completion: @escaping (Result<User>) -> Void) {
        guard let fanLogoutURL = self.makeURL(with: "fan/logout") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(fanLogoutURL, method: .post, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanUserResponse>) in

                switch dataResponse.result {
                case .success(let fanUserResponse): completion(.success(fanUserResponse.user))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanUser(register registrationPayload: RestApiFanUserRegistrationRequestPayload, completion: @escaping (Result<UserProfile>) -> Void) {
        guard let fanProfileURL = self.makeURL(with: "fan/register") else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin": self.originURI]

        do {
            let jsonData = try JSONEncoder().encode(registrationPayload)

            var request = URLRequest(url: fanProfileURL)
            request.httpMethod = HTTPMethod.post.rawValue
            var allHTTPHeaderFields: HTTPHeaders = request.allHTTPHeaderFields ?? HTTPHeaders()
            allHTTPHeaderFields += headers
            request.allHTTPHeaderFields = allHTTPHeaderFields
            request.httpBody = jsonData

            Alamofire.request(request).validate().restApiResponse { (dataResponse: DataResponse<FanRegistrationResponse>) in
                switch dataResponse.result {
                case .success(let fanRegiatrationResponse): completion(.success(fanRegiatrationResponse.userProfile))
                case .failure(let error): completion(.failure(error))
                }
            }

        } catch {
            completion(.failure(error))
        }

    }


    func fanUser(restorePassword restorePasswordPayload: RestApiFanUserRestorePasswordRequestPayload, completion: @escaping (Result<String>) -> Void) {
        guard let fanRestorePasswordURL = self.makeURL(with: "fan/forgot-password") else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        do {
            let jsonData = try JSONEncoder().encode(restorePasswordPayload)

            var request = URLRequest(url: fanRestorePasswordURL)
            request.httpMethod = HTTPMethod.post.rawValue
            var allHTTPHeaderFields: HTTPHeaders = request.allHTTPHeaderFields ?? HTTPHeaders()
            allHTTPHeaderFields += headers
            request.allHTTPHeaderFields = allHTTPHeaderFields
            request.httpBody = jsonData

            Alamofire.request(request).validate().restApiResponse { (dataResponse: DataResponse<FanForgotPasswordResponse>) in
                switch dataResponse.result {
                case .success(let fanForgotPasswordResponse): completion(.success(fanForgotPasswordResponse.message))
                case .failure(let error): completion(.failure(error))
                }
            }

        } catch {
            completion(.failure(error))
        }
    }



    func fanUser<T: RestApiProfileRequestPayload>(update profilePayload: T, completion: @escaping (Result<User>) -> Void) {
        guard let fanProfileURL = self.makeURL(with: "fan/profile") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        do {
            let jsonData = try JSONEncoder().encode(profilePayload)

            var request = URLRequest(url: fanProfileURL)
            request.httpMethod = HTTPMethod.put.rawValue
            var allHTTPHeaderFields: HTTPHeaders = request.allHTTPHeaderFields ?? HTTPHeaders()
            allHTTPHeaderFields += headers
            request.allHTTPHeaderFields = allHTTPHeaderFields
            request.httpBody = jsonData

            Alamofire.request(request).validate().restApiResponse { (dataResponse: DataResponse<FanProfileResponse>) in
                switch dataResponse.result {
                case .success(let fanUserResponse): completion(.success(fanUserResponse.user))
                case .failure(let error): completion(.failure(error))
                }
            }

        } catch {
            completion(.failure(error))
        }
    }
    
    func fanPlaylists(completion: @escaping (Result<[PlaylistShort]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "fan/playlist") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        
        Alamofire.request(playlistsURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistsShortResponse>) in
                
                switch dataResponse.result {
                case .success(let playlistsResponse): completion(.success(playlistsResponse.playlists))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
    
    func fanTracks(for playlistId: Int, completion: @escaping (Result<[Track]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "fan/playlist/" + String(playlistId) + "/record") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(playlistsURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistTracksResponse>) in
                
                switch dataResponse.result {
                case .success(let playlistTracksResponse): completion(.success(playlistTracksResponse.tracks))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanMove(_ track: Track, to playlist: PlaylistShort, completion: @escaping (Result<[Int]>) -> Void) {
        guard let moveTrackURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/attach-items") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        
        let parameters: Parameters = ["records" :[["id" : track.id]]]
        
        Alamofire.request(moveTrackURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<TrackMoveResponse>) in
                switch dataResponse.result {
                case .success(let moveTrackResponse): completion(.success(moveTrackResponse.recordIds))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
    
    func fanDelete(_ track: Track, from playlist: PlaylistShortInfo, completion: @escaping (Error?) -> Void) {
        guard let removeTrackURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/record/" + String(track.id)) else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        
        Alamofire.request(removeTrackURL, method: .delete, headers: headers)
            .validate()
            .response { (response) in
                completion(response.error)
        }
    }
    
    func fanCreatePlaylist(with name: String, completion: @escaping (Result<PlaylistShort>) -> Void) {
        guard let createPlaylistURL = self.makeURL(with: "fan/playlist") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]
        
        let parameters: Parameters = ["name" : name]

        Alamofire.request(createPlaylistURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistsCreateShortResponse>) in
                switch dataResponse.result {
                case .success(let playlistsResponse): completion(.success(playlistsResponse.playlist))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
    
    // MARK: - Player

    func audioAddons(for trackIds: [Int], completion: @escaping (Result<[Int : [Addon]]>) -> Void) {
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

                    switch dataResponse.result {
                    case .success(let addonsForTracksResponse): completion(.success(addonsForTracksResponse.trackAddons))
                    case .failure(let error): completion(.failure(error))
                    }
            }

        } catch (let error) {
            completion(.failure(error))
        }
    }

    func artists(with artistIds: [String], completion: @escaping (Result<[Artist]>) -> Void ) {
        guard let artistTracksURL = self.makeURL(with: "player/artist") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json"]
        let jsonQuery = ["filters" : ["id" : ["in" : artistIds]]]

        do {
            let jsonQueryData = try JSONSerialization.data(withJSONObject: jsonQuery)
            guard let jsonQueryString = String(data: jsonQueryData, encoding: .utf8) else { return }

            let parameters: Parameters = ["jsonQuery" : jsonQueryString]

            Alamofire.request(artistTracksURL, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
                .validate()
                .restApiResponse { (dataResponse: DataResponse<ArtistsResponse>) in

                    switch dataResponse.result {
                    case .success(let artistsResponse): completion(.success(artistsResponse.artists))
                    case .failure(let error): completion(.failure(error))
                    }
            }

        } catch (let error) {
            completion(.failure(error))
        }
    }

    func playlists(completion: @escaping (Result<[Playlist]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "player/playlists") else { return }

        Alamofire.request(playlistsURL, method: .get)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistsResponse>) in

                switch dataResponse.result {
                case .success(let playlistsResponse): completion(.success(playlistsResponse.playlists))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func tracks(for playlistId: Int, completion: @escaping (Result<[Track]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "player/records/" + String(playlistId)) else { return }

        Alamofire.request(playlistsURL, method: .get)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistTracksResponse>) in

                switch dataResponse.result {
                case .success(let playlistTracksResponse): completion(.success(playlistTracksResponse.tracks))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    // MARK: - Config -

    func config(completion: @escaping (Result<Config>) -> Void) {
        guard let configURL = self.makeURL(with: "config") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(configURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<ConfigResponse>) in

                switch dataResponse.result {
                case .success(let configResponse): completion(.success(configResponse.config))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    // MARK: - Location -

    func countries(completion: @escaping (Result<[Country]>) -> Void) {
        guard let countriesURL = self.makeURL(with: "gis/country") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(countriesURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<CountriesResponse>) in

                switch dataResponse.result {
                case .success(let countriesResponse): completion(.success(countriesResponse.countries))
                case .failure(let error): completion(.failure(error))
                }
        }

    }

    func regions(for country: Country, completion: @escaping (Result<[Region]>) -> Void) {
        guard let statesURL = self.makeURL(with: "gis/country/" + country.code + "/state") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(statesURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<RegionsResponse>) in

                switch dataResponse.result {
                case .success(let regionsResponse): completion(.success(regionsResponse.regions))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func cities(for region: Region, completion: @escaping (Result<[City]>) -> Void) {
        guard let citiesURL = self.makeURL(with: "gis/country/" + region.countryCode + "/state/" + String(region.id)) else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        Alamofire.request(citiesURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<CitiesResponse>) in

                switch dataResponse.result {
                case .success(let citiesResponse): completion(.success(citiesResponse.cities))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func location(for country: Country, zip: String, completion: @escaping (Result<DetailedLocation>) -> Void) {
        guard let locationURL = self.makeURL(with: "gis/location") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json"]

        let parameters: Parameters = ["country_code": country.code,
                                      "postal_code": zip]

        Alamofire.request(locationURL, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<DetailedLocationResponse>) in

                switch dataResponse.result {
                case .success(let detatailedLocationResponse): completion(.success(detatailedLocationResponse.detailedLocation))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
}
