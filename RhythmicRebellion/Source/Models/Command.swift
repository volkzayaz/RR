//
//  Command.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

enum Command {

    enum Command: String {
        case playListLoadTracks = "playlist-loadTracks"
        case playListUpdate = "playlist-update"
        case currentTrackId = "currentTrack-setTrack"
        case currentTrackState = "currentTrack-setState"
    }

    enum CodingKeys: String, CodingKey {
        case channel
        case cmd
        case data
    }

    case unknown
    case playListLoadTracks([Track])
    case playListUpdate([String : PlayListItem])
    case currentTrackId(TrackId)
    case currentTrackState(TrackState)
}

extension Command: Decodable {

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let chanelValue = try container.decode(String.self, forKey: .channel) 
        let commandValue = try container.decode(String.self, forKey: .cmd)

        let commandRawValue = (chanelValue != nil) ? chanelValue + "-" + commandValue : commandValue

        guard let command = Command(rawValue: commandRawValue) else { self = .unknown; return }

        do {
            switch command {
            case .playListLoadTracks:
                let tracks = try container.decode([Track].self, forKey: .data)
                self = .playListLoadTracks(tracks)
            case .playListUpdate:
                let playList = try container.decode([String : PlayListItem].self, forKey: .data)
                self = .playListUpdate(playList)
            case .currentTrackId:
                let trackId = try container.decode(TrackId.self, forKey: .data)
                self = .currentTrackId(trackId)
            case .currentTrackState:
                let trackState = try container.decode(TrackState.self, forKey: .data)
                self = .currentTrackState(trackState)
            }
        } catch (let error) {
            print("error: \(error)")
            self = .unknown
        }

    }
}
