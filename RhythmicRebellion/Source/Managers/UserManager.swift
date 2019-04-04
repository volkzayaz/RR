//
//  UserManager.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/3/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

////TODO: apply optimistic policy for all 4 requests
enum UserManager { }
extension UserManager {
    
    static func allowPlayTrackWithExplicitMaterial(trackId: Int, shouldAllow: Bool) -> Maybe<Void> {
        
        return UserRequest.allowExplicitMaterial(trackId: trackId, shouldAllow: shouldAllow)
            .rx.response(type: TrackForceToPlayState.self)
            .do(onNext: { (newState) in
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user.profile?.update(with: newState)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: newState))
            })
            .map { _ in () }
        
    }
    
    static func updateSkipAddons(for artist: Artist, skip: Bool) -> Maybe<Void> {
        
        return UserRequest.skipAddonRule(for: artist, shouldSkip: skip)
            .rx.baseResponse(type: User.self)
            .do(onNext: { (user) in
                
                Dispatcher.dispatch(action: SetNewUser(user: user))
                
                let skipArtistAddonsState = SkipArtistAddonsState(artistId: artist.id,
                                                                  isSkipped: user.isAddonsSkipped(for: artist))
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: skipArtistAddonsState))
            })
            .map { _ in () }
        
    }
    
    static func update(track: Track, likeState: Track.LikeStates) -> Maybe<Void> {
        
        return UserRequest.like(track: track, state: likeState)
            .rx.response(type: TrackLikeState.self)
            .do(onNext: { (state) in
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user.profile?.update(with: state)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: state))
            })
            .map { _ in () }
        
    }
    
    static func follow(shouldFollow: Bool, artistId: String) -> Maybe<Void> {
        
        return UserRequest.follow(artistId: artistId, shouldFollow: shouldFollow)
            .rx.emptyResponse()
            .do(onNext: {
                
                let state = ArtistFollowingState(artistId: artistId,
                                                 isFollowed: shouldFollow)
                
                Dispatcher.dispatch(action: UpdateUser { user in
                    user.profile?.update(with: state)
                })
                
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: state))
            })
            .map { _ in () }
        
    }
    
}
