//
//  Decodable.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Alamofire

struct ErrorResponse: Decodable {

    let code: Int?
    let message: String
    let errors: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case message
        case meta
        case code = "errorCode"
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
        
        self.code = try? container.decode(Int.self, forKey: .code) ?? -1
    }
}

struct FanUserResponse: Decodable {

    let user: User

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.user = try container.decode(User.self, forKey: .data)
        
    }
}

struct FanLoginResponse: Decodable {

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

        self.user = try container.decode(User.self, forKey: .user)
    }
}

struct FanForgotPasswordResponse: Decodable {

    let message: String

    enum CodingKeys: String, CodingKey {
        case message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.message = try container.decode(String.self, forKey: .message)
    }
}

struct FanRegistrationResponse: Decodable {

    let message: String

}


struct FanProfileResponse: Decodable {

    let user: User

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try container.decode(User.self, forKey: .data)
    }
}

struct ArtistsResponse: Decodable {

    let artists: [Artist]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artists = try container.decode([Artist].self, forKey: .data)
    }
}


struct DefinedPlaylistsResponse: Decodable {

    let playlists: [DefinedPlaylist]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlists = try container.decode([DefinedPlaylist].self)
    }
}

struct FanPlaylistsResponse: Decodable {
    
    let playlists: [FanPlaylist]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlists = try container.decode([FanPlaylist].self)
    }
}


struct PlaylistTracksResponse: Decodable {
    let tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tracks = try container.decode([Track].self, forKey: .data)
    }
}

struct FanPlaylistResponse: Decodable {
    
    let playlist: FanPlaylist
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.playlist = try container.decode(FanPlaylist.self)
    }
}

struct AttachTracksResponse: Decodable {
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

struct AttachDefinedPlaylistResponse: Decodable {
    let recordIds: [Int: Int]

    enum CodingKeys: String, CodingKey {
        case data
    }

    enum RecordsKeys: String, CodingKey {
        case recordIds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let recordsContainer = try container.nestedContainer(keyedBy: RecordsKeys.self, forKey: .data)

        let recordsOrderInfo = try recordsContainer.decode([Int : [String : Int] ].self, forKey: .recordIds)
        self.recordIds = recordsOrderInfo.reduce(into: [:]) { (result , keyValue) in
            let (key, value) = keyValue
            result[key] = value["sort_order"]
        }
    }
}

struct TrackForceToPlayResponse: Decodable {

    let fanId: Int
    let state: TrackForceToPlayState

    enum CodingKeys: String, CodingKey {
        case fanId = "fan_id"
        case recordId = "record_id"
        case forceToPlay = "force_to_play"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.fanId = try container.decode(Int.self, forKey: .fanId)
        self.state = TrackForceToPlayState(trackId: try container.decode(Int.self, forKey: .recordId),
                                           isForcedToPlay: try container.decode(Bool.self, forKey: .forceToPlay))
    }
}

struct FollowArtistResponse: Decodable {

    let fanUserId: Int
    let state: ArtistFollowingState

    enum CodingKeys: String, CodingKey {
        case fanUserId = "fan_id"
        case artistId = "artist_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.fanUserId = try container.decode(Int.self, forKey: .fanUserId)
        self.state = ArtistFollowingState(artistId: try container.decode(String.self, forKey: .artistId),
                                          isFollowed: true)
    }

}

struct TrackLikeStateResponse: Decodable {

    let fanUserId: Int
    let state: TrackLikeState

    enum CodingKeys: String, CodingKey {
        case fanUserId = "fan_id"
        case trackId = "record_id"
        case likeState = "type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.fanUserId = try container.decode(Int.self, forKey: .fanUserId)
        self.state = TrackLikeState(id: try container.decode(Int.self, forKey: .trackId),
                                    state: try container.decode(Track.LikeStates.self, forKey: .likeState))
    }

}

struct LyricsResponse: Decodable {

    let lyrics: Lyrics

    enum CodingKeys: String, CodingKey {
        case lyrics = "data"
    }
}

// MARK: - Config -

struct ConfigResponse: Decodable {

    let config: Config

    enum CodingKeys: String, CodingKey {
        case config = "data"
    }

}

struct GenresResponse: Decodable {

    let genres: [Genre]

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.genres = try container.decode([Genre].self, forKey: .data)
    }
}

struct CountriesResponse: Decodable {

    let countries: [Country]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.countries = try container.decode([Country].self)
    }
}

struct RegionsResponse: Decodable {

    let regions: [Region]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.regions = try container.decode([Region].self)
    }
}

struct CitiesResponse: Decodable {

    let cities: [CityInfo]

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.cities = try container.decode([CityInfo].self)
    }
}

struct DetailedLocationResponse: Decodable {

    let detailedLocation: DetailedLocation

    enum CodingKeys: String, CodingKey {
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.detailedLocation = try container.decode(DetailedLocation.self, forKey: .data)
    }
}
