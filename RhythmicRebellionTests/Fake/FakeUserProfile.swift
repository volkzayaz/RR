//
//  FakeUserProfile.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/6/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

@testable import RhythmicRebellion

extension UserProfile: Fakeble {
    
    static func fake() -> UserProfile {
        return UserProfile(withID: 10,
                           email: "fake@mail.com",
                           nickname: "nickname",
                           firstName: "firstName",
                           location: ProfileLocation.fake(),
                           hobbies: [Hobby](),
                           forceToPlay: Set<Int>(),
                           followedArtistsIds: Set<String>(),
                           purchasedAlbumsIds: Set<Int>(),
                           purchasedTracksIds: Set<Int>(),
                           tracksLikeStates: [:],
                           skipAddonsArtistsIds: Set<String>(),
                           listeningSettings: ListeningSettings.fake())
    }
}
