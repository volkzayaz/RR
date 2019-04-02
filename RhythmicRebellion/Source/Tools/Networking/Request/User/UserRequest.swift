//
//  UserRequest.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/2/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

enum UserRequest: BaseNetworkRouter {
    
    case login ///cokie based, always returns BaseResponse<User>
    case logout ///clears cokies
    
    case signIn(login: String, password: String) ///returns FanLoginResponse
    case register(data: RegisterData) ////returns FanRegistrationResponse
    
    case updateProfile(_ x: UserProfilePayload) ///return BaseResponse<User>
    case updateListeningSettings(_ x: ListeningSettingsPayload) ///return BaseResponse<User>
    
    case restorePassword(email: String) ////FanForgotPasswordResponse
    case changeEmail(to: String, currentPassword: String) ////Empty
    case changePassword(old: String, new: String, confirm: String) ///BaseResponse<User>
    
    case allowExplicitMaterial(trackId: Int, shouldAllow: Bool)/// TrackForceToPlayState
    case skipAddonRule(for: Artist, shouldSkip: Bool) ///BaseResponse<User>
    
    case like(track: Track, state: Track.LikeStates) ///TrackLikeState
    case follow(artistId: String, shouldFollow: Bool) ///ArtistFollowingState
}

extension UserRequest {
    
    func asURLRequest() throws -> URLRequest {

        switch self {
            
        case .login:
            return anonymousRequest(method: .get, path: "fan/user")

        case .logout:
            return anonymousRequest(method: .post, path: "fan/logout")
            
        case .signIn(let login, let password):
            
            return anonymousRequest(method: .post,
                                    path: "fan/login",
                                    params: ["email" : login,
                                             "password" : password],
                                    encoding: JSONEncoding.default)
            
        case .register(let data):
            
            return anonymousRequest(method: .post,
                                    path: "fan/register",
                                    encodableParam: data)
            
        case .updateProfile(let x):
            
            return anonymousRequest(method: .put,
                                    path: "fan/profile",
                                    encodableParam: x)
            
        case .updateListeningSettings(let x):
            
            return anonymousRequest(method: .put,
                                    path: "fan/profile/update-listening-settings",
                                    encodableParam: x)
            
        case .restorePassword(let email):
            
            return anonymousRequest(method: .post,
                                    path: "fan/forgot-password",
                                    params: ["email": email])
            
        case .changeEmail(let to, let pwd):
            
            return anonymousRequest(method: .post,
                                    path: "fan/profile/change-email",
                                    params: ["email": to,
                                             "current_password": pwd])
            
        case .changePassword(let old, let new, let confirm):
            
            return anonymousRequest(method: .put,
                                    path: "fan/profile/change-password",
                                    params: ["current_password": old,
                                             "new_password": new,
                                             "new_password_confirmation": confirm])
            
        case .allowExplicitMaterial(let trackId, let shouldAllow):
            
            return anonymousRequest(method: shouldAllow ? .post : .delete,
                                    path: "fan/listen-record/\(trackId)/force-to-play")
         
        case .skipAddonRule(let `for`, let shouldSkip):
            
            return anonymousRequest(method: shouldSkip ? .delete : .post,
                                    path: "fan/profile/skip-add-ons-for-artist/\(`for`.id)")

        case .like(let track, let state):
            
            return anonymousRequest(method: .post,
                                    path: "fan/record-like/\(track.id)",
                                    params: ["type": state.rawValue])
            
        case .follow(let artistId, let shouldFollow):
            
            return anonymousRequest(method: shouldFollow ? .post : .delete,
                                    path: "fan/artist-follow/\(artistId)")
            
        }
        
    }
    
}
