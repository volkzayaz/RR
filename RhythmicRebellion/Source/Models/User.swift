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


public protocol User: Decodable {

    var isGuest: Bool { get }
    var wsToken: String { get }

    func isCensorshipTrack(_ track: Track) -> Bool
    func stubTrackAudioFileReason(for track: Track) -> UserStubTrackAudioFileReason?

    func isFollower(for artist: Artist) -> Bool
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

    func isFollower(for artist: Artist) -> Bool {
        return false
    }
}

struct UserProfile: Decodable {

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
//    var purchasedTracksIds: [Int]

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

    func isCensorshipTrack(_ track: Track) -> Bool {
        return track.isCensorship && self.profile.listeningSettings.isExplicitMaterialExcluded
    }


    func stubTrackAudioFileReason(for track: Track) -> UserStubTrackAudioFileReason? {

        guard self.isCensorshipTrack(track), !self.profile.forceToPlay.contains(track.id) else { return nil }
        return .censorship
    }

    func isFollower(for artist: Artist) -> Bool {
        return self.profile.followedArtistsIds.contains(artist.id)
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



