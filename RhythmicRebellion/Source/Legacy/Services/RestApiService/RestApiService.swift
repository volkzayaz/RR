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

    func fanUser(completion: @escaping (Result<User>) -> Void) {

        guard let fanUserURL = self.makeURL(with: "fan/user") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

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
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]
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
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

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

            let request = try self.makeRequest(with: fanProfileURL,
                                               httpMethod: HTTPMethod.post,
                                               headers: headers,
                                               requestPayload: registrationPayload)

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

            let request = try self.makeRequest(with: fanRestorePasswordURL,
                                               httpMethod: HTTPMethod.post,
                                               headers: headers,
                                               requestPayload: restorePasswordPayload)

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

    func fanUser(changeEmail changeEmailPayload: RestApiFanUserChangeEmailRequestPayload, completion: @escaping (Result<Void>) -> Void) {
        guard let fanChangeEmailURL = self.makeURL(with: "fan/profile/change-email") else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]


        do {
            let request = try self.makeRequest(with: fanChangeEmailURL,
                                               httpMethod: HTTPMethod.put,
                                               headers: headers,
                                               requestPayload: changeEmailPayload)

            Alamofire.request(request).validate().restApiResponse { (dataResponse: DataResponse<DefaultEmptyRestApiResponse>) in
                switch dataResponse.result {
                case .success(_): completion(.success(()))
                case .failure(let error): completion(.failure(error))
                }
            }

        } catch {
            completion(.failure(error))
        }

    }

    func fanUser(changePassword changePasswordPayload: RestApiFanUserChangePasswordRequestPayload, completion: @escaping (Result<User>) -> Void) {
        guard let fanChangePasswordURL = self.makeURL(with: "fan/profile/change-password") else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        do {
            let request = try self.makeRequest(with: fanChangePasswordURL,
                                               httpMethod: HTTPMethod.put,
                                               headers: headers,
                                               requestPayload: changePasswordPayload)

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


    func fanUser<T: RestApiProfileRequestPayload>(update profilePayload: T, completion: @escaping (Result<User>) -> Void) {

        func fanProfileURL(for profilePayload: RestApiProfileRequestPayload) -> URL? {
            switch profilePayload {
            case _ as RestApiProfileSettingsRequestPayload: return self.makeURL(with: "fan/profile")
            case _ as RestApiListeningSettingsRequestPayload: return self.makeURL(with: "fan/profile/update-listening-settings")
            default: return nil
            }
        }

        guard let fanProfileURL = fanProfileURL(for: profilePayload) else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        do {
            let request = try self.makeRequest(with: fanProfileURL,
                                               httpMethod: HTTPMethod.put,
                                               headers: headers,
                                               requestPayload: profilePayload)

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
    
    func fanCreatePlaylist(with name: String, completion: @escaping (Result<FanPlaylist>) -> Void) {
        guard let createPlaylistURL = self.makeURL(with: "fan/playlist") else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]
        
        let parameters: Parameters = ["name" : name]

        Alamofire.request(createPlaylistURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanPlaylistResponse>) in
                switch dataResponse.result {
                case .success(let playlistsResponse): completion(.success(playlistsResponse.playlist))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanDelete(playlist: FanPlaylist, completion: @escaping (Error?) -> Void) {
        guard let deletePlaylistURL = self.makeURL(with: "fan/playlist/" + String(playlist.id)) else { return }

        let headers: HTTPHeaders = ["Accept" : "application/json",
                                    "Content-Type" : "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(deletePlaylistURL, method: .delete, headers: headers)
            .validate()
            .response { (response) in
                completion(response.error)
        }
    }

    func fanAllowPlayTrackWithExplicitMaterial(trackId: Int, shouldAllow: Bool, completion: @escaping (Result<(TrackForceToPlayState)>) -> Void) {
        guard let forceToPlayURL = self.makeURL(with: "fan/listen-record/" + String(trackId) + "/force-to-play") else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(forceToPlayURL, method: shouldAllow ? .post : .delete, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<TrackForceToPlayResponse>) in
                switch dataResponse.result {
                case .success(let trackForceToPlayResponse): completion(.success(trackForceToPlayResponse.state))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanFollow(shouldFollow: Bool, artistId: String, completion: @escaping (Result<ArtistFollowingState>) -> Void) {
        guard let followArtistURL = self.makeURL(with: "fan/artist-follow/" + String(artistId)) else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(followArtistURL,
                          method: shouldFollow ? .post : .delete,
                          headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FollowArtistResponse>) in
                switch dataResponse.result {
                case .success(let followArtistResponse):
                    guard artistId == followArtistResponse.state.artistId else { completion(.failure(AppError(.unexpectedResponse))); return }
                    completion(.success(followArtistResponse.state))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func updateSkipArtistAddons(for artist: Artist, skip: Bool, completion: @escaping (Result<User>) -> Void) {
        guard let skipAddonURL = self.makeURL(with: "fan/profile/skip-add-ons-for-artist/" + artist.id) else { return }

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        let method: HTTPMethod = skip ? .post : .delete

        Alamofire.request(skipAddonURL, method: method, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<FanProfileResponse>) in
                switch dataResponse.result {
                case .success(let fanProfileResponse): completion(.success(fanProfileResponse.user))
                case .failure(let error): completion(.failure(error))
                }
        }
    }

    func fanUpdate(track: Track, likeState: Track.LikeStates, completion: @escaping (Result<TrackLikeState>) -> Void) {
        guard let trackLikeURL = self.makeURL(with: "fan/record-like/" + String(track.id)) else { return }

        let parameters: Parameters = ["type" : likeState.rawValue]

        let headers: HTTPHeaders = ["Accept": "application/json",
                                    "Content-Type": "application/json",
                                    "Origin" : self.originURI]

        Alamofire.request(trackLikeURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .restApiResponse { (dataResponse: DataResponse<TrackLikeStateResponse>) in
                switch dataResponse.result {
                case .success(let trackLikeStateResponse): completion(.success(trackLikeStateResponse.state))
                case .failure(let error): completion(.failure(error))
                }
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
