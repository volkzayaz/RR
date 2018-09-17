//
//  RestApiResponse.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

public protocol RestApiResponse: Decodable {
}

public protocol EmptyRestApiResponse: RestApiResponse {
    init()
}

struct ErrorResponse: RestApiResponse {

    let message: String
    let errors: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case message
        case meta
    }

    enum MetaCodingKeys: String, CodingKey {
        case errors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.message = try container.decode(String.self, forKey: .message)

        if let metaContainer = try? container.nestedContainer(keyedBy: MetaCodingKeys.self, forKey: .meta) {
            self.errors = try metaContainer.decode([String : [String]].self, forKey: .errors)
        } else {
            self.errors = [:]
        }
    }
}

struct FanUserResponse: RestApiResponse {

    let user: User

    enum CodingKeys: String, CodingKey {
        case data
    }

    enum DataCodingKeys: String, CodingKey {
        case guest
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dataContainer = try container.nestedContainer(keyedBy: DataCodingKeys.self, forKey: .data)

        let isGuest = try dataContainer.decode(Bool.self, forKey: .guest)

        if isGuest {
            self.user = try container.decode(GuestUser.self, forKey: .data)
        } else {
            self.user = try container.decode(FanUser.self, forKey: .data)
        }
    }
}

struct FanLoginResponse: RestApiResponse {

    let user: User

    enum CodingKeys: String, CodingKey {
        case user
        case meta
    }

    enum UserCodingKeys: String, CodingKey {
        case guest
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let userContainer = try container.nestedContainer(keyedBy: UserCodingKeys.self, forKey: .user)

        let isGuest = try userContainer.decode(Bool.self, forKey: .guest)

        if isGuest {
            self.user = try container.decode(GuestUser.self, forKey: .user)
        } else {
            self.user = try container.decode(FanUser.self, forKey: .user)
        }
    }
}

struct FanForgotPasswordResponse: RestApiResponse {

    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.message = try container.decode(String.self, forKey: .message)
    }
}

struct FanRegistrationResponse: RestApiResponse {

    let userProfile: UserProfile
    let message: String

    enum CodingKeys: String, CodingKey {
        case userProfile = "user"
        case message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.message = try container.decode(String.self, forKey: .message)
        self.userProfile = try container.decode(UserProfile.self, forKey: .userProfile)
    }
}


struct FanProfileResponse: RestApiResponse {

    let user: User

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try container.decode(FanUser.self, forKey: .data)
    }
}

struct AddonsForTracksResponse: EmptyRestApiResponse {

    let trackAddons: [Int : [Addon]]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init() {
        self.trackAddons = [Int : [Addon]]()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var intKeyAddonInfo = [Int : [Addon]]()

        do {
            let stringKeyAddonInfo = try container.decode([String : [Addon]].self, forKey: .data)

            for (stringId, addons) in stringKeyAddonInfo {
                guard let intKey = Int(stringId) else { continue }
                intKeyAddonInfo[intKey] = addons
            }

            self.trackAddons = intKeyAddonInfo
        } catch (let error) {
            guard let emptyAddons = try? container.decodeIfPresent([Addon].self, forKey: .data), emptyAddons?.isEmpty ?? false else { throw error }
            self.trackAddons = intKeyAddonInfo
        }
    }
}

struct ArtistsResponse: RestApiResponse {

    let artists: [Artist]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artists = try container.decode([Artist].self, forKey: .data)
    }
}


struct PlaylistsResponse: RestApiResponse {

    let playlists: [Playlist]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlists = try container.decode([Playlist].self)
    }
}

struct PlaylistsShortResponse: RestApiResponse {
    
    let playlists: [PlaylistShort]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlists = try container.decode([PlaylistShort].self)
    }
}


struct PlaylistTracksResponse: RestApiResponse {
    let tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tracks = try container.decode([Track].self, forKey: .data)
    }
}

struct PlaylistsCreateShortResponse: RestApiResponse {
    
    let playlist: PlaylistShort
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlist = try container.decode(PlaylistShort.self)
    }
}

struct TrackMoveResponse: RestApiResponse {
    let recordIds: [Int]
    
    enum CodingKeys: String, CodingKey {
        case data
    }
    
    enum RecordsKeys: String, CodingKey {
        case recordIds
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let recordsContainer = try container.nestedContainer(keyedBy: RecordsKeys.self, forKey: .data)
        self.recordIds = try recordsContainer.decode([Int].self, forKey: .recordIds)
    }
}

// MARK: - Config -

struct PlayerConfigResponse: RestApiResponse {

    let playerConfig: PlayerConfig

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.playerConfig = try container.decode(PlayerConfig.self, forKey: .data)
    }
}

struct ConfigResponse: RestApiResponse {

    let config: Config

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.config = try container.decode(Config.self, forKey: .data)
    }
}

struct GenresResponse: RestApiResponse {

    let genres: [Genre]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.genres = try container.decode([Genre].self, forKey: .data)
    }
}

struct CountriesResponse: RestApiResponse {

    let countries: [Country]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.countries = try container.decode([Country].self)
    }
}

struct RegionsResponse: RestApiResponse {

    let regions: [Region]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.regions = try container.decode([Region].self)
    }
}

struct CitiesResponse: RestApiResponse {

    let cities: [City]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.cities = try container.decode([City].self)
    }
}

struct DetailedLocationResponse: RestApiResponse {

    let detailedLocation: DetailedLocation

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.detailedLocation = try container.decode(DetailedLocation.self, forKey: .data)
    }
}
