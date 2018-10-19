//
//  WebSocketService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Starscream
import os.log

protocol WebSocketServiceObserver: class {

    func webSocketServiceDidConnect(_ service: WebSocketService)
    func webSocketServiceDidDisconnect(_ service: WebSocketService)

    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings)
    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState)
    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState)

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track])
    func webSocketService(_ service: WebSocketService, didReceivePlaylist playlistLinkedItems: [String: PlayerPlaylistLinkedItem?])
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?)
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState)
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool)
    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons)
    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool)
}

extension WebSocketServiceObserver {

    func webSocketServiceDidConnect(_ service: WebSocketService) { }
    func webSocketServiceDidDisconnect(_ service: WebSocketService) { }

    func webSocketService(_ service: WebSocketService, didReceiveListeningSettings listeningSettings: ListeningSettings) { }
    func webSocketService(_ service: WebSocketService, didReceiveTrackForceToPlayState trackForceToPlayState: TrackForceToPlayState) { }
    func webSocketService(_ service: WebSocketService, didReceiveArtistFollowingState artistFollowingState: ArtistFollowingState) { }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) { }
    func webSocketService(_ service: WebSocketService, didReceivePlaylist playlistLinkedItems: [String: PlayerPlaylistLinkedItem?]) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool) { }
    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons) { }
    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool) { }
}

class WebSocketService: WebSocketDelegate, Observable {

    typealias ObserverType = WebSocketServiceObserver

    let observersContainer = ObserversContainer<WebSocketServiceObserver>()

    var webSocket: WebSocket?
    var token: Token?

    var webSocketURL: URL

    var isReachable: Bool = false
    var isConnected: Bool { return self.webSocket?.isConnected ?? false }

    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "WebSocketService")

    init?(webSocketURI: String) {
        guard let webSocketURL = URL(string: webSocketURI) else { return nil }
        
        self.webSocketURL = webSocketURL
    }

    func makeWebSocket() -> WebSocket {
        var request = URLRequest(url: self.webSocketURL)
        request.timeoutInterval = 1

        let webSocket = WebSocket(request: request)
        webSocket.delegate = self

        return webSocket
    }

    func connect(with token: Token) {
        self.token = token

        print("connect with Token: \(self.token)")

        self.webSocket = self.makeWebSocket()
        self.webSocket?.connect()
    }

    func reconnect() {
        guard let _ = self.token else { return }

        print("reconnect with Token: \(self.token)")

        self.webSocket = self.makeWebSocket()
        self.webSocket?.connect()
    }

    func disconnect() {
        self.webSocket?.disconnect()
    }

    func sendCommand(command: WebSocketCommand, completion: ((Error?) -> ())? = nil) {

        guard self.webSocket?.isConnected == true else { completion?(AppError(WebSocketServiceError.offline)); return }


//        #if DEBUG
//        if command.commandType == .playAddon {
//            completion?(nil)
//            return
//        }
//        #endif

        do {
            let jsonData = try JSONEncoder().encode(command)

            self.webSocket?.write(data: jsonData, completion: { completion?(nil) })
        } catch (let error) {
            completion?(AppError(WebSocketServiceError.custom(error)))
        }
    }

    // MARK: - WebSocketDelegate -
    public func websocketDidConnect(socket: WebSocketClient) {

        if let token = self.token {
            let initialCommand = WebSocketCommand.initialCommand(token: token)
            self.sendCommand(command: initialCommand)
        }

        self.observersContainer.invoke({ (observer) in
            observer.webSocketServiceDidConnect(self)
        })
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect: \(String(describing: error))")

        self.observersContainer.invoke({ (observer) in
            observer.webSocketServiceDidDisconnect(self)
        })
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let data = text.data(using: .utf8) else { return }

        self.websocketDidReceiveData(socket: socket, data: data)
    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {

        do {
            let webSoketCommand = try JSONDecoder().decode(WebSocketCommand.self, from: data)

            switch webSoketCommand.data {
            case .success(let successWebSocketData):
                switch successWebSocketData {

                case .userInit( _ ):
                    break

                case .userSyncListeningSettings(let listeningSettings):

                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveListeningSettings: listeningSettings)
                    })

                case .userSyncForceToPlay(let trackForceToPlayState):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveTrackForceToPlayState: trackForceToPlayState)
                    })

                case .userSyncFollowing(let artistFollowingState):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveArtistFollowingState: artistFollowingState)
                    })

                case .playListLoadTracks(let tracks):

                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveTracks: tracks)
                    })

                case .playListUpdate(let playerPlaylist):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceivePlaylist: playerPlaylist)
                    })

                case .currentTrackId(let trackId):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCurrentTrackId: trackId)
                    })

                case .currentTrackState(let trackState):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCurrentTrackState: trackState)
                    })

                case .currentTrackBlock(let isBlocked):

                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCurrentTrackBlock: isBlocked)
                    })

                case .checkAddons(let checkAddons):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCheckAddons: checkAddons)
                    })

                case .playAddon(let addonState):
                    print("addonState: \(addonState)")

                case .tracksTotalPlayTime(let tracksTotalPlayMSeconds):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveTracksTotalPlayTime: tracksTotalPlayMSeconds, flush: webSoketCommand.flush ?? false)
                    })
                }

            case .failure(let error):
                print(error)

            case .unknown:
                print("Unknown channel: \(webSoketCommand.channel) command: \(webSoketCommand.command)")
                print("websocketDidReceiveMessage: \(String(describing: String(data: data, encoding: .utf8)))")
            }

        } catch (let error) {
            print(error.localizedDescription)
            print("websocketDidReceiveMessage: \(String(describing: String(data: data, encoding: .utf8)))")
        }
    }
}
