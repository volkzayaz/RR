//
//  User.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/29/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation


public enum UserStubTrackAudioFileReason {
    case censorship
}


public protocol User: Codable {

    var isGuest: Bool { get }
    var wsToken: String { get }

    func isCensorshipTrack(_ track: Track) -> Bool
    func stubTrackAudioFileReason(for track: Track) -> UserStubTrackAudioFileReason?

    func isFollower(for artistId: String) -> Bool
    func hasPurchase(for track: Track) -> Bool

    func likeState(for track: Track) -> Track.LikeStates
    func isAddonsSkipped(for artist: Artist) -> Bool
}

//func == (lhs: User, rhs: User) -> Bool {
//    guard type(of: lhs) == type(of: rhs) else { return false }
//    return lhs.wsToken == rhs.wsToken
//}


struct GuestUser: User {

    let isGuest: Bool
    let wsToken: String

    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
        case isGuest = "guest"
    }

    func isCensorshipTrack(_ track: Track) -> Bool {
        return track.isCensorship
    }

    func stubTrackAudioFileReason(for track: Track) -> UserStubTrackAudioFileReason? {

        guard self.isCensorshipTrack(track) else { return nil}
        return .censorship
    }

    func isFollower(for artistId: String) -> Bool { return false }
    func hasPurchase(for track: Track) -> Bool { return false }
    func likeState(for track: Track) -> Track.LikeStates { return .none }
    func isAddonsSkipped(for artist: Artist) -> Bool { return false }
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
    let howHearId: Int
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
        case howHearId = "how_hear"
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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = ModelSupport.sharedInstance.dateTimeFormattre


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
        self.howHearId = try container.decode(Int.self, forKey: .howHearId)

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

        if let gender = self.gender {
            try container.encode(gender.rawValue, forKey: .gender)
        }

        try container.encodeAsString(self.birthDate, forKey: .birthDate, dateFormatter: dateTimeFormatter)
        try container.encode(self.location, forKey: .location)

        try container.encode(self.phone, forKey: .phone)

        try container.encode(self.hobbies, forKey: .hobbies)
        try container.encode(self.howHearId, forKey: .howHearId)

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
                lhs.language == rhs.language
    }
}

struct FanUser: User {

    var profile: UserProfile
    let wsToken: String
    let isGuest: Bool = false

    enum CodingKeys: String, CodingKey {
        case wsToken = "ws_token"
    }

    init(from decoder: Decoder) throws {
        self.profile = try UserProfile(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wsToken = try container.decode(String.self, forKey: .wsToken)
    }

    public func encode(to encoder: Encoder) throws {

        try self.profile.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.wsToken, forKey: .wsToken)

    }

    func isCensorshipTrack(_ track: Track) -> Bool {
        return track.isCensorship && self.profile.listeningSettings.isExplicitMaterialExcluded
    }


    func stubTrackAudioFileReason(for track: Track) -> UserStubTrackAudioFileReason? {

        guard self.isCensorshipTrack(track), !self.profile.forceToPlay.contains(track.id) else { return nil }
        return .censorship
    }

    func isFollower(for artistId: String) -> Bool {
        return self.profile.followedArtistsIds.contains(artistId)
    }

    func hasPurchase(for track: Track) -> Bool {
        return self.profile.purchasedTracksIds.contains(track.id)
    }

    func likeState(for track: Track) -> Track.LikeStates {
        guard let trackLikeState = self.profile.tracksLikeStates[track.id] else { return .none }
        return trackLikeState
    }

    func isAddonsSkipped(for artist: Artist) -> Bool {
        return self.profile.skipAddonsArtistsIds.contains(artist.id)
    }

}

extension FanUser: Equatable {
    static func == (lhs: FanUser, rhs: FanUser) -> Bool {
        guard lhs.profile.id == rhs.profile.id else { return false }
        return true
    }
}

func == (lhs: User, rhs: User) -> Bool {
    if let _ = lhs as? GuestUser, let _ = rhs as? GuestUser { return true }
    if let lhsFanUser = lhs as? FanUser, let rhsFanUser = rhs as? FanUser { return lhsFanUser == rhsFanUser }

    return false
}

func != (lhs: User, rhs: User) -> Bool {
    if let _ = lhs as? GuestUser, let _ = rhs as? GuestUser { return false }
    if let lhsFanUser = lhs as? FanUser, let rhsFanUser = rhs as? FanUser { return lhsFanUser.profile.id != rhsFanUser.profile.id }

    return true
}


