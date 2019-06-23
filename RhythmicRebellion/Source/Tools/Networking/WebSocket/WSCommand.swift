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
    
    associatedtype DataType
    var data: DataType { get }
    
    init(jsonData: Data) throws
    var jsonData: Data { get }
}

///WebSocket data that we can parse using Codable
struct CodableWebSocketCommand<T: Codable>: Codable, WSCommand {
    
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
    
    init(data: T, channel: String, command: String) {
        self.channel = channel
        self.command = command
        
        self.data = data
        
        self.flush = nil
    }
    
    init(jsonData: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            self = try decoder.decode(CodableWebSocketCommand<T>.self, from: jsonData)
        }
        catch (let e) {
            fatalError("Error trying to decode \(CodableWebSocketCommand<T>.self). Details: \(e)")
        }
    }
    
    var jsonData: Data {
        
        let x = JSONEncoder()
        x.dateEncodingStrategy = .iso8601
        
        return try! JSONEncoder().encode(self)
    }
    
}

extension CodableWebSocketCommand where T: WSCommandData {
    
    init(data: T) {
        self.init(data: data, channel: T.channel, command: T.command)
    }
    
}

struct TrackReduxViewPatch: WSCommand {
    
    let data: LinkedPlaylist.NullableReduxView
    let shouldFlush: Bool
    
    init(data: LinkedPlaylist.NullableReduxView, shouldFlush: Bool) {
        self.data = data
        self.shouldFlush = shouldFlush
    }
    
    init(jsonData: Data) {
        
        guard let x = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = x as? [String: Any],
            let data = dictionary[CodableWebSocketCommand<Int>.CodingKeys.data.rawValue] as? [TrackOrderHash: [String: Any?]?] else {
                fatalError("Error decoding data for TrackReduxViewPatch")
        }
        
        self.data = data.mapValues { (maybePatch) -> [LinkedPlaylist.ViewKey: Any?]? in
            
            guard let x = maybePatch else {
                return nil
            }
            
            var p: [LinkedPlaylist.ViewKey: Any?] = [:]
            
            x.forEach { (key, value) in
                
                var v: Any? = value
                if v is NSNull { v = nil }
                
                p[ LinkedPlaylist.ViewKey(rawValue: key)! ] = v
            }
            
            return p
        }
        
        self.shouldFlush = dictionary[CodableWebSocketCommand<Int>.CodingKeys.flush.rawValue] as? Bool ?? false
        
    }
    
    var jsonData: Data {
        
        let data: [String: [String: Any?]?] = self.data.mapValues { (maybePatch: [LinkedPlaylist.ViewKey: Any?]?) -> [String: Any?]? in
            
            guard let x = maybePatch else {
                return nil
            }
            
            var p: [String: Any?] = [:]
            
            x.forEach { (key, value) in
                p[ key.rawValue ] = value ?? NSNull()
            }
            
            return p
        }
        
        
        let x: [String: Any] = [ CodableWebSocketCommand<Int>.CodingKeys.channel.rawValue: TrackReduxViewPatch.DataType.channel,
                                 CodableWebSocketCommand<Int>.CodingKeys.command.rawValue: TrackReduxViewPatch.DataType.command,
                                 CodableWebSocketCommand<Int>.CodingKeys.data.rawValue   : data,
                                 CodableWebSocketCommand<Int>.CodingKeys.flush.rawValue  : shouldFlush
                                 ]
        
        let p = try! JSONSerialization.data(withJSONObject: x, options: [])
        
        return p
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

extension Dictionary: WSCommandData where Key == TrackOrderHash, Value == Dictionary<LinkedPlaylist.ViewKey, Any?>? {
    static var channel: String { return "playlist" }
    static var command: String { return "update" }
}

extension TrackState: WSCommandData {
    static var channel: String { return "currentTrack" }
    static var command: String { return "setState" }
}

extension TrackId: WSCommandData {
    static var channel: String { return "currentTrack" }
    static var command: String { return "setTrack" }
}

typealias TrackBlockState = Bool
extension TrackBlockState: WSCommandData {
    static var channel: String { return "currentTrack" }
    static var command: String { return "setBlock" }
}


extension Optional: WSCommandData where Wrapped: WSCommandData {
    static var channel: String { return Wrapped.channel }
    static var command: String { return Wrapped.command }
}

extension CheckAddons: WSCommandData {
    static var channel: String { return "addons" }
    static var command: String { return "checkAddons" }
}

extension AddonState: WSCommandData {
    static var channel: String { return "addons" }
    static var command: String { return "playAddon" }
}
