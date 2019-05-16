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
        
        let followingArtistsIds = Set<String>([
            "4102abcd-b6a8-421f-8b54-d09dcc53c161",
            "4102abcd-b6a8-421f-8b54-d09dcc53c162",
            "4102abcd-b6a8-421f-8b54-d09dcc53c163",
            "4102abcd-b6a8-421f-8b54-d09dcc53c164",
            "4102abcd-b6a8-421f-8b54-d09dcc53c165"])
        
        return UserProfile(withID: 10,
                           email: "fake@mail.com",
                           nickname: "nickname",
                           firstName: "firstName",
                           location: ProfileLocation.fake(),
                           hobbies: [Hobby](),
                           forceToPlay: Set<Int>(),
                           followedArtistsIds: followingArtistsIds,
                           purchasedAlbumsIds: Set<Int>(),
                           purchasedTracksIds: Set<Int>(),
                           tracksLikeStates: [:],
                           skipAddonsArtistsIds: Set<String>(),
                           listeningSettings: ListeningSettings.fake())
    }
}
