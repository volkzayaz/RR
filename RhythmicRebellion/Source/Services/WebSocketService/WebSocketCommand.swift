//
//  Command.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

struct CommandErrorData: Codable {

    let isError: Bool
    let message: String

    enum CodingKeys: String, CodingKey {
        case isError = "error"
        case message = "msg"
    }
}


struct WebSocketCommand: Codable {

    enum CommandType: String {
        case userInit = "user-init"
        case playListLoadTracks = "playlist-loadTracks"
        case playListUpdate = "playlist-update"
        case currentTrackId = "currentTrack-setTrack"
        case currentTrackState = "currentTrack-setState"
        case unknown
    }

    enum SuccessCommandData {
        case userInit(Token)
        case playListLoadTracks([Track])
        case playListUpdate([String : PlayListItem])
        case currentTrackId(TrackId)
        case currentTrackState(TrackState)
    }

    enum CommandData {
        case success(SuccessCommandData)
        case faile(CommandErrorData)
        case unknown
    }

    var commandType: CommandType {
        return CommandType(rawValue: self.channel + "-" + self.command) ?? .unknown
    }

    let channel: String
    let command: String
    var flush: Bool?

    let data: CommandData

    enum CodingKeys: String, CodingKey {
        case channel
        case command = "cmd"
        case flush
        case data
    }

    init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.channel = try container.decode(String.self, forKey: .channel)
        self.command = try container.decode(String.self, forKey: .command)
        self.flush = try container.decodeIfPresent(Bool.self, forKey: .flush)

        let commandType = CommandType(rawValue: self.channel + "-" + self.command) ?? .unknown

        do {
            switch commandType {
            case .userInit:
                self.data = .success(.userInit(try container.decode(Token.self, forKey: .data)))
            case .playListLoadTracks:
                self.data = .success(.playListLoadTracks(try container.decode([Track].self, forKey: .data)))
            case .playListUpdate:
                self.data = .success(.playListUpdate(try container.decode([String : PlayListItem].self, forKey: .data)))
            case .currentTrackId:
                self.data = .success(.currentTrackId(try container.decode(TrackId.self, forKey: .data)))
            case .currentTrackState:
                self.data = .success(.currentTrackState(try container.decode(TrackState.self, forKey: .data)))
            case .unknown:
                self.data = .unknown
            }
        } catch (let error) {
            guard let errorData = try container.decodeIfPresent(CommandErrorData.self, forKey: .data) else { throw error }
            self.data = .faile(errorData)
        }
    }

    init(channel: String, command: String, data: CommandData) {
        self.channel = channel
        self.command = command
        self.data = data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channel, forKey: .channel)
        try container.encode(command, forKey: .command)
        if let flush = self.flush {
            try container.encode(flush, forKey: .flush)
        }

        switch data {
        case .success(let successCommandData):
            switch successCommandData {
            case .userInit(let token):
                try container.encode(token, forKey: .data)
            case .playListLoadTracks(let traks):
                try container.encode(traks, forKey: .data)
            case .playListUpdate(let playlist):
                try container.encode(playlist, forKey: .data)
            case .currentTrackId(let trackId):
                try container.encode(trackId, forKey: .data)
            case .currentTrackState(let trackState):
                try container.encode(trackState, forKey: .data)
            }
        case .faile( let errorData):
            try container.encode(errorData, forKey: .data)
        case .unknown:
            break
        }
    }
}


extension WebSocketCommand {
    static func initialCommand(token: Token) -> WebSocketCommand {
        return WebSocketCommand(channel: "user", command: "init", data: .success(.userInit(token)))
    }

    static func setCurrentTrack(trackId: TrackId) -> WebSocketCommand {
        return WebSocketCommand(channel: "currentTrack", command: "setTrack", data: .success(.currentTrackId(trackId)))
    }

    static func setTrackState(trackState: TrackState) -> WebSocketCommand {
        return WebSocketCommand(channel: "currentTrack", command: "setState", data: .success(.currentTrackState(trackState)))
    }
}
