//
//  ListeningSettings.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct ListeningSettings: Codable {

    var isSongCommentary: Bool
    var isSongCommentaryDate: Bool
    var songCommentaryDate: Date?

    var isHearArtistsBio: Bool
    var isHearArtistsBioDate: Bool
    var artistsBioDate: Date?

    var isExplicitMaterialExcluded: Bool

    enum CodingKeys: String, CodingKey {
        case isSongCommentary = "is_song_commentary"
        case isSongCommentaryDate = "is_song_commentary_date"
        case songCommentaryDate = "song_commentary_date"

        case isHearArtistsBio = "is_hear_artists_bio"
        case isHearArtistsBioDate = "is_hear_artists_bio_date"
        case artistsBioDate = "artists_bio_date"

        case isExplicitMaterialExcluded = "is_explicit_material_excluded"
    }

    static func defaultSettings() -> ListeningSettings {
        return ListeningSettings(isSongCommentary: true, isSongCommentaryDate: false, isHearArtistsBio: true, isHearArtistsBioDate: false, isExplicitMaterialExcluded: false)
    }

    init(isSongCommentary: Bool, isSongCommentaryDate: Bool, songCommentaryDate: Date? = Date(), isHearArtistsBio: Bool, isHearArtistsBioDate: Bool, artistsBioDate: Date? = Date(), isExplicitMaterialExcluded: Bool) {
        self.isSongCommentary = isSongCommentary
        self.isSongCommentaryDate = isSongCommentaryDate
        self.songCommentaryDate = songCommentaryDate

        self.isHearArtistsBio = isHearArtistsBio
        self.isHearArtistsBioDate = isHearArtistsBioDate
        self.artistsBioDate = artistsBioDate

        self.isExplicitMaterialExcluded = isExplicitMaterialExcluded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.isSongCommentary = try container.decode(Bool.self, forKey: .isSongCommentary)
        self.isSongCommentaryDate = try container.decode(Bool.self, forKey: .isSongCommentaryDate)

        if let songCommentaryDateString = try? container.decode(String.self, forKey: .songCommentaryDate) {
            self.songCommentaryDate = ModelSupport.sharedInstance.date(from: songCommentaryDateString)
        } else {
            self.songCommentaryDate = nil
        }

        self.isHearArtistsBio = try container.decode(Bool.self, forKey: .isHearArtistsBio)
        self.isHearArtistsBioDate = try container.decode(Bool.self, forKey: .isHearArtistsBioDate)

        if let artistsBioDateString = try? container.decode(String.self, forKey: .artistsBioDate) {
            self.artistsBioDate = ModelSupport.sharedInstance.date(from: artistsBioDateString)
        } else {
            self.artistsBioDate = nil
        }

        self.isExplicitMaterialExcluded = try container.decode(Bool.self, forKey: .isExplicitMaterialExcluded)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.isSongCommentary, forKey: .isSongCommentary)
        try container.encode(self.isSongCommentaryDate, forKey: .isSongCommentaryDate)

        var songCommentaryDateString: String? = nil
        if let songCommentaryDate = self.songCommentaryDate {
            songCommentaryDateString = ModelSupport.sharedInstance.string(from: songCommentaryDate)
        }
        try container.encode(songCommentaryDateString, forKey: .songCommentaryDate)

        try container.encode(self.isHearArtistsBio, forKey: .isHearArtistsBio)
        try container.encode(self.isHearArtistsBioDate, forKey: .isHearArtistsBioDate)

        var artistsBioDateString: String? = nil
        if let artistsBioDate = self.artistsBioDate {
            artistsBioDateString = ModelSupport.sharedInstance.string(from: artistsBioDate)
        }
        try container.encode(artistsBioDateString, forKey: .artistsBioDate)

        try container.encode(self.isExplicitMaterialExcluded, forKey: .isExplicitMaterialExcluded)
    }
}

extension ListeningSettings: Equatable {
    static func == (lhs: ListeningSettings, rhs: ListeningSettings) -> Bool {
        return lhs.isSongCommentary == rhs.isSongCommentary &&
                lhs.isSongCommentaryDate == rhs.isSongCommentaryDate &&
                lhs.isHearArtistsBio == rhs.isHearArtistsBio &&
                lhs.isHearArtistsBioDate == rhs.isHearArtistsBioDate &&
                lhs.isExplicitMaterialExcluded == rhs.isExplicitMaterialExcluded &&
                lhs.songCommentaryDate == rhs.songCommentaryDate &&
                lhs.artistsBioDate == rhs.artistsBioDate 
    }
}

