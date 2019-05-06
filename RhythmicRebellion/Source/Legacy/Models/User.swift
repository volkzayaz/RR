//
//  User.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


struct User: Codable, Equatable {
    
    var profile: UserProfile?
    let wsToken: String
    var isGuest: Bool {
        return profile == nil
    }
    
    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
        case guest
    }
    
    init(withUserProfile profile: UserProfile, wsToken: String) {
        self.profile = profile
        self.wsToken = wsToken
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wsToken = try container.decode(String.self, forKey: .wsToken)
        
        let isGuest = try container.decode(Bool.self, forKey: .guest)
        profile = isGuest ? nil : try UserProfile(from: decoder)
        
    }
    
    public func encode(to encoder: Encoder) throws {
        
        //TODO: Need check
        //try self.profile.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.wsToken, forKey: .wsToken)
        try container.encode(profile == nil, forKey: .guest)
        
    }
    
    func shouldCensorTrack(_ track: Track) -> Bool {

        if !track.isCensorship {
            ///track does not contain explicit materials
            return false
        }

        guard let p = profile else {
            ///user is guest
            return true
        }
        
        if !p.listeningSettings.isExplicitMaterialExcluded {
            ///user opted in to listen to all songs
            return false
        }
        
        ///user opted in to listen to this particular track
        return !p.forceToPlay.contains(track.id)
        
    }
    
    func isFollower(for artistId: String) -> Bool {
        return self.profile?.followedArtistsIds.contains(artistId) ?? false
    }
    
    func hasPurchase(for track: Track) -> Bool {
        return self.profile?.purchasedTracksIds.contains(track.id) ?? false
    }
    
    func likeState(for track: Track) -> Track.LikeStates {
        guard let trackLikeState = self.profile?.tracksLikeStates[track.id] else { return .none }
        return trackLikeState
    }
    
    func isAddonsSkipped(for artist: Artist) -> Bool {
        return self.profile?.skipAddonsArtistsIds.contains(artist.id) ?? false
    }
    
}

struct UserProfile: Codable {

    let id: Int
    let email: String
    var nickname: String
    var firstName: String
    var gender: Gender?
    var birthDate: Date?
    var location: ProfileLocation
    var phone: String?
    var hobbies: [Hobby]
    var genres: [Genre]?
    var language: String?
    var forceToPlay: Set<Int>
    var followedArtistsIds: Set<String>
    var purchasedAlbumsIds: Set<Int>
    var purchasedTracksIds: Set<Int>
    var tracksLikeStates: [Int : Track.LikeStates]
    var skipAddonsArtistsIds: Set<String>

    var listeningSettings: ListeningSettings

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case email
        case nickname = "nick_name"
        case firstName = "real_name"
        case gender
        case birthDate = "birth_date"
        case location
        case phone
        case hobbies
        case genres
        case language
        case forceToPlay = "force_to_play"
        case listeningSettings = "listening_settings"
        case followedArtistsIds = "artists_followed"
        case purchasedAlbumsIds = "purchased_albums_ids"
        case purchasedTracksIds = "purchased_tracks_ids"
        case tracksLikeStates = "likes"
        case skipAddonsArtistsIds = "skip_add_ons_for_artist_ids"
    }
    
    init(withID id: Int,
         email: String,
         nickname: String,
         firstName: String,
         location: ProfileLocation,
         hobbies: [Hobby],
         forceToPlay: Set<Int>,
         followedArtistsIds: Set<String>,
         purchasedAlbumsIds: Set<Int>,
         purchasedTracksIds: Set<Int>,
         tracksLikeStates:  [Int : Track.LikeStates],
         skipAddonsArtistsIds: Set<String>,
         listeningSettings: ListeningSettings,
         genres: [Genre]? = nil,
         gender: Gender? = nil,
         birthDate: Date? = nil,
         phone: String? = nil,
         language: String? = nil) {
        
        self.id = id
        self.email = email
        self.nickname = nickname
        self.firstName = firstName
        self.location = location
        self.hobbies = hobbies
        self.genres = genres
        self.gender = gender
        self.birthDate = birthDate
        self.phone = phone
        self.language = language
        self.forceToPlay = forceToPlay
        self.followedArtistsIds = followedArtistsIds
        self.purchasedAlbumsIds = purchasedAlbumsIds
        self.purchasedTracksIds = purchasedTracksIds
        self.tracksLikeStates = tracksLikeStates
        self.skipAddonsArtistsIds = skipAddonsArtistsIds
        self.listeningSettings = listeningSettings
    }

    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ModelSupport.sharedInstance.dateFormatter

        self.id = try container.decode(Int.self, forKey: .id)
        self.email = try container.decode(String.self, forKey: .email)
        self.nickname = try container.decode(String.self, forKey: .nickname)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        if let genderRowValue = try? container.decode(Int.self, forKey: .gender) {
            self.gender = Gender(rawValue: genderRowValue)
        } else {
            self.gender = nil
        }

        self.birthDate = try container.decodeAsDate(String.self, forKey: .birthDate, dateFormatter: dateFormatter)
        self.location = try container.decode(ProfileLocation.self, forKey: .location)
        self.phone = try container.decodeIfPresent(String.self, forKey: .phone)
        self.hobbies = try container.decode([Hobby].self, forKey: .hobbies)
        
        self.genres = try container.decodeIfPresent([Genre].self, forKey: .genres)
        self.language = try container.decodeIfPresent(String.self, forKey: .language)

        self.listeningSettings = try container.decode(ListeningSettings.self, forKey: .listeningSettings)

        if let forceToPlay = try container.decodeIfPresent(Set<Int>.self, forKey: .forceToPlay) {
            self.forceToPlay = forceToPlay
        } else {
            self.forceToPlay = Set<Int>()
        }

        if let followedArtistsIds = try container.decodeIfPresent(Set<String>.self, forKey: .followedArtistsIds) {
            self.followedArtistsIds = followedArtistsIds
        } else {
            self.followedArtistsIds = Set<String>()
        }

        if let purchasedAlbumsIds = try container.decodeIfPresent(Set<Int>.self, forKey: .purchasedAlbumsIds) {
            self.purchasedAlbumsIds = purchasedAlbumsIds
        } else {
            self.purchasedAlbumsIds = Set<Int>()
        }

        if let purchasedTracksIds = try container.decodeIfPresent(Set<Int>.self, forKey: .purchasedTracksIds) {
            self.purchasedTracksIds = purchasedTracksIds
        } else {
            self.purchasedTracksIds = Set<Int>()
        }

        if let tracksLikeStates = try container.decodeIfPresent([Int : Track.LikeStates].self, forKey: .tracksLikeStates) {
            self.tracksLikeStates = tracksLikeStates
        } else {
            self.tracksLikeStates = [:]
        }

        if let skipAddonsArtistsIds = try container.decodeIfPresent(Set<String>.self, forKey: .skipAddonsArtistsIds) {
            self.skipAddonsArtistsIds = skipAddonsArtistsIds
        } else {
            self.skipAddonsArtistsIds = Set<String>()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateTimeFormatter = ModelSupport.sharedInstance.dateTimeFormattre

        try container.encode(self.id, forKey: .id)
        try container.encode(self.email, forKey: .email)
        try container.encode(self.nickname, forKey: .nickname)
        try container.encode(self.firstName, forKey: .firstName)

        try container.encode(gender?.rawValue ?? 0, forKey: .gender)

        try container.encodeAsString(self.birthDate, forKey: .birthDate, dateFormatter: dateTimeFormatter)
        try container.encode(self.location, forKey: .location)

        try container.encode(self.phone, forKey: .phone)

        try container.encode(self.hobbies, forKey: .hobbies)

        try container.encode(self.genres, forKey: .genres)
        try container.encode(self.language, forKey: .language)

        try container.encode(self.listeningSettings, forKey: .listeningSettings)

        try container.encode(self.forceToPlay, forKey: .forceToPlay)
        try container.encode(self.followedArtistsIds, forKey: .followedArtistsIds)
        try container.encode(self.purchasedAlbumsIds, forKey: .purchasedAlbumsIds)
        try container.encode(self.purchasedTracksIds, forKey: .purchasedTracksIds)
        try container.encode(self.tracksLikeStates, forKey: .tracksLikeStates)
        try container.encode(self.skipAddonsArtistsIds, forKey: .skipAddonsArtistsIds)
    }

    mutating func update(with trackForceToPlayState: TrackForceToPlayState) {
        if trackForceToPlayState.isForcedToPlay {
            forceToPlay.insert(trackForceToPlayState.trackId)
        } else {
            forceToPlay.remove(trackForceToPlayState.trackId)
        }
    }

    mutating func update(with artistFollowingState: ArtistFollowingState) {
        if artistFollowingState.isFollowed {
            followedArtistsIds.insert(artistFollowingState.artistId)
        } else {
            followedArtistsIds.remove(artistFollowingState.artistId)
        }
    }

    mutating func update(with skipArtistAddonsState: SkipArtistAddonsState) {
        if skipArtistAddonsState.isSkipped {
            skipAddonsArtistsIds.insert(skipArtistAddonsState.artistId)
        } else {
            skipAddonsArtistsIds.remove(skipArtistAddonsState.artistId)
        }
    }

    mutating func update(with purchases: [Purchase]) {

        let purchasedTracksIds = purchases.filter { $0.modelType == .track }.map { return $0.modelId }
        guard purchasedTracksIds.isEmpty == false else { return }

        self.purchasedTracksIds = Set(purchasedTracksIds).union(self.purchasedTracksIds)

    }

    mutating func update(with trackLikeState: TrackLikeState) {
        self.tracksLikeStates[trackLikeState.id] = trackLikeState.state
    }

}

extension UserProfile: Equatable {
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id &&
                lhs.email == rhs.email &&
                lhs.firstName == rhs.firstName &&
                lhs.nickname == rhs.nickname &&
                lhs.gender == rhs.gender &&
                lhs.birthDate == rhs.birthDate &&
                lhs.location == rhs.location &&
                lhs.phone == rhs.phone &&
                lhs.hobbies == rhs.hobbies &&
                lhs.genres == rhs.genres &&
                lhs.language == rhs.language &&
                lhs.followedArtistsIds == rhs.followedArtistsIds &&
                lhs.tracksLikeStates == rhs.tracksLikeStates &&
                lhs.listeningSettings == rhs.listeningSettings &&
                lhs.forceToPlay == rhs.forceToPlay
    }
}
