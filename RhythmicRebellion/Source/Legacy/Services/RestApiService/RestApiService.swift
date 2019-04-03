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




    
    func fanPlaylists(completion: @escaping (Result<[FanPlaylist]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "fan/playlist") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]
        
        Alamofire.request(playlistsURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanPlaylistsResponse>) in
                
                switch dataResponse.result {
                case .success(let playlistsResponse): completion(.success(playlistsResponse.playlists))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
    
    func fanTracks(for playlistId: Int, completion: @escaping (Result<[Track]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "fan/playlist/" + String(playlistId) + "/record") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(playlistsURL, method: .get, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<PlaylistTracksResponse>) in
                
                switch dataResponse.result {
                case .success(let playlistTracksResponse): completion(.success(playlistTracksResponse.tracks))
                case .failure(let error): completion(.failure(error))
                }
        }
    }


    func fanAttach(playlist attachingPlaylist: DefinedPlaylist, to playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        guard let fanAttachPlaylistURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/attach-playlists") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        let parameters: Parameters = ["playlist_id" : attachingPlaylist.id]


        Alamofire.request(fanAttachPlaylistURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .response { (response) in
                completion(response.error)
        }

    }


    func fanAttach(playlist attachingPlaylist: FanPlaylist, to playlist: FanPlaylist, completion: @escaping (Result<[Int]>) -> Void) {
        guard let fanAttachPlaylistURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/attach-fan-playlists") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        let parameters: Parameters = ["playlist_id" : attachingPlaylist.id]


        Alamofire.request(fanAttachPlaylistURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<AttachTracksResponse>) in
                switch dataResponse.result {
                case .success(let attachTracksResponse): completion(.success(attachTracksResponse.recordIds))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanAttach(_ tracks: [Track], to playlist: FanPlaylist, completion: @escaping (Result<[Int]>) -> Void) {
        guard let moveTrackURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/attach-items") else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        let parameters: Parameters = ["records" : tracks.map { ["id" : $0.id] }]
        
        Alamofire.request(moveTrackURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<AttachTracksResponse>) in
                switch dataResponse.result {
                case .success(let attachTracksResponse): completion(.success(attachTracksResponse.recordIds))
                case .failure(let error): completion(.failure(error))
                }
        }
    }
    
    func fanDelete(_ track: Track, from playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        guard let removeTrackURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/record/" + String(track.id)) else { return }
        
        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]
        
        Alamofire.request(removeTrackURL, method: .delete, headers: headers)
            .validate()
            .response { (response) in
                completion(response.error)
        }
    }

    func fanClear(playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        guard let clearPlaylistURL = self.makeURL(with: "fan/playlist/" + String(playlist.id) + "/clear") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(clearPlaylistURL, method: .post, headers: headers)
            .validate()
            .response { (response) in
                completion(response.error)
        }
    }

    func playlists(completion: @escaping (Result<[DefinedPlaylist]>) -> Void) {
        guard let playlistsURL = self.makeURL(with: "player/playlists") else { return }

        Alamofire.request(playlistsURL, method: .get)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<DefinedPlaylistsResponse>) in

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

}
