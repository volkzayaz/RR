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

///Any type that can be represented by "data" field from WebSocket
protocol WSCommandData {
    static var channel: String { get }
    static var command: String { get }
}

////Anything that we receive from WebSocket
protocol WSCommand {
    
    associatedtype DataType: WSCommandData
    var data: DataType { get }
    
    init(jsonData: Data) throws
    var jsonData: Data { get }
}

///WebSocket data that we can parse using Codable
struct CodableWebSocketCommand<T: WSCommandData & Codable>: Codable, WSCommand {
    
    let channel: String
    let command: String
    let data: T
    let flush: Bool?

    enum CodingKeys: String, CodingKey {
        case channel
        case command = "cmd"
        case flush
        case data
    }
    
    init(data: T) {
        channel = T.channel
        command = T.command
        
        self.data = data
        
        self.flush = nil
    }
    
    init(jsonData: Data) {
        do {
            self = try JSONDecoder().decode(CodableWebSocketCommand<T>.self, from: jsonData)
        }
        catch (let e) {
            fatalError("Error trying to decode \(CodableWebSocketCommand<T>.self). Details: \(e)")
        }
    }
    
    var jsonData: Data {
        return try! JSONEncoder().encode(self)
    }
    
}

struct TrackReduxViewPatch: WSCommand {
    
    let data: DaPlaylist.NullableReduxView
    
    init(jsonData: Data) {
        
        guard let x = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = x as? [String: Any],
            let data = dictionary[CodableWebSocketCommand<Int>.CodingKeys.data.rawValue] as? [TrackOrderHash: [String: Any?]?] else {
                fatalError("Error decoding data for TrackReduxViewPatch")
        }
        
        self.data = data.mapValues { (maybePatch) -> [DaPlaylist.ViewKey: Any?]? in
            
            guard let x = maybePatch else {
                return nil
            }
            
            var p: [DaPlaylist.ViewKey: Any?] = [:]
            
            x.forEach { (key, value) in
                
                var v: Any? = value
                if v is NSNull {
                    v = nil
                }
                
                p[ DaPlaylist.ViewKey(rawValue: key)! ] = v
            }
            
            return p
        }
        
    }
    
    var jsonData: Data {
        
        let x: [String: Any] = [ CodableWebSocketCommand<Int>.CodingKeys.channel.rawValue: TrackReduxViewPatch.DataType.channel,
                                 CodableWebSocketCommand<Int>.CodingKeys.command.rawValue: TrackReduxViewPatch.DataType.command,
                                 CodableWebSocketCommand<Int>.CodingKeys.data.rawValue   : self.data]
        
        return try! JSONSerialization.data(withJSONObject: x, options: [])
    }
    
}


extension Token: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "init" }
}

extension Array : WSCommandData where Element: WSCommandData {
    static var channel: String { return Element.channel }
    static var command: String { return Element.command }
}

typealias LoadTracks = Int
extension LoadTracks: WSCommandData {
    static var channel: String { return "playlist" }
    static var command: String { return "getTracks" }
}

extension Track : WSCommandData {
    static var channel: String { return "playlist" }
    static var command: String { return "loadTracks" }
}

extension ListeningSettings: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "syncListeningSettings" }
}

extension TrackForceToPlayState: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "syncForceToPlay" }
}

extension SkipArtistAddonsState: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "syncSkipArtistBioCommentary" }
}

extension TrackLikeState: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "syncLike" }
}

extension ArtistFollowingState: WSCommandData {
    static var channel: String { return "user" }
    static var command: String { return "syncFollowing" }
}

extension FanPlaylistState: WSCommandData {
    static var channel: String { return "states" }
    static var command: String { return "customPlaylistsStates" }
}

extension Dictionary: WSCommandData where Key == TrackOrderHash, Value == Dictionary<DaPlaylist.ViewKey, Any?>? {
    static var channel: String { return "update" }
    static var command: String { return "playlist" }
}

extension TrackState: WSCommandData {
    static var channel: String { return "currentTrack" }
    static var command: String { return "setState" }
}



extension WSCommand {
//    static func initialCommand(token: Token) -> WSCommand<Token> {
//        return WebSocketCommand<Token>(data: token)
//    }

//    static func syncListeningSettings(listeningSettings: ListeningSettings) -> WebSocketCommand {
//        return WebSocketCommand(channel: "user", command: "syncListeningSettings", data: listeningSettings)
//    }
//
//    static func syncForceToPlay(trackForceToPlayState: TrackForceToPlayState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "user", command: "syncForceToPlay", data: trackForceToPlayState)
//    }
//
//    static func syncFollowing(artistFollowingState: ArtistFollowingState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "user", command: "syncFollowing", data: artistFollowingState)
//    }
//
//    static func syncArtistAddonsState(skipArtistAddonsState: SkipArtistAddonsState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "user", command: "syncSkipArtistBioCommentary", data: skipArtistAddonsState)
//    }
//
//    static func syncTrackLikeState(trackLikeState: TrackLikeState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "user", command: "syncLike", data: trackLikeState)
//    }
//
//    static func getTracks(tracksIds: [Int]) -> WebSocketCommand {
//        return WebSocketCommand(channel: "playlist", command: "getTracks", data: tracksIds)
//    }
//
//    static func setCurrentTrack(trackId: TrackId) -> WebSocketCommand {
//        return WebSocketCommand(channel: "currentTrack", command: "setTrack", data: trackId)
//    }
//
//    static func setTrackState(trackState: TrackState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "currentTrack", command: "setState", data: trackState)
//    }
//
//    static func setTrackBlock(isBlocked: Bool) -> WebSocketCommand {
//        return WebSocketCommand(channel: "currentTrack", command: "setBlock", data: isBlocked)
//    }
//
//    static func checkAddons(checkAddons: CheckAddons) -> WebSocketCommand {
//        return WebSocketCommand(channel: "addons", command: "checkAddons", data: checkAddons)
//    }
//
//    static func playAddon(addonState: AddonState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "addons", command: "playAddon", data: addonState)
//    }
//
//    static func loadTracks(tracks: [Track]) -> WebSocketCommand {
//        return WebSocketCommand(channel: "playlist", command: "loadTracks", data: tracks)
//    }
//
//    static func updatePlaylist(playlistItemsPatches: [String: PlayerPlaylistItemPatch?]) -> WebSocketCommand {
//        return WebSocketCommand(channel: "playlist", command: "update", data: playlistItemsPatches)
//    }
//
//    static func trackingTimeRequest(for trackIds: [Int]) -> WebSocketCommand {
//
//        let trackIdsData = trackIds.reduce([Int:UInt64]()) { (result, trackId) -> [Int:UInt64] in
//            var result = result
//            result[trackId] = 0
//            return result
//        }
//
//        return WebSocketCommand(channel: "previewOpt", command: "srts_previews", data: trackIdsData)
//    }
//
//    static func fanPlaylistsStates(for fanPlaylistState: FanPlaylistState) -> WebSocketCommand {
//        return WebSocketCommand(channel: "states", command: "customPlaylistsStates", data: fanPlaylistState)
//    }

}
