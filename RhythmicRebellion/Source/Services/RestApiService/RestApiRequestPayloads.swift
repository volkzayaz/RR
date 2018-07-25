//
//  RestApiRequestPayloads.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/25/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

protocol RestApiRequestPayload: Encodable {

}

protocol RestApiProfileRequestPayload: RestApiRequestPayload {

}

struct RestApiListeningSettingsRequestPayload: RestApiProfileRequestPayload {

    let listeningSettings: ListeningSettings

    init(with listeningSettings: ListeningSettings) {
        self.listeningSettings = listeningSettings
    }

    enum CodingKeys: String, CodingKey {
        case listeningSettings = "listening_settings"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(listeningSettings, forKey: .listeningSettings)
    }
}
