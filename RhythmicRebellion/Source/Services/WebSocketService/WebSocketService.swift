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

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track])
    func webSocketService(_ service: WebSocketService, didReceivePlayList playList: [String: PlayListItem])
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?)
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState)
}

extension WebSocketServiceObserver {

    func webSocketServiceDidConnect(_ service: WebSocketService) { }
    func webSocketServiceDidDisconnect(_ service: WebSocketService) { }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) { }
    func webSocketService(_ service: WebSocketService, didReceivePlayList playList: [String: PlayListItem]) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) { }

}

class WebSocketService: WebSocketDelegate, Observable {

    typealias ObserverType = WebSocketServiceObserver

    let observersContainer = ObserversContainer<WebSocketServiceObserver>()

    var webSocket: WebSocket
    var token: Token?

    var isReachable: Bool = true
    var isConnected: Bool { return self.webSocket.isConnected }

    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "WebSocketService")

    init(with url: URL) {

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        self.webSocket = WebSocket(request: request)
        self.webSocket.delegate = self
    }

    func connect(with token: Token) {
        self.token = token

        print("self.token: \(self.token)")

        self.webSocket.connect()
    }

    func reconnect() {
        self.webSocket.connect()
    }

    func disconnect() {
        self.webSocket.disconnect()
    }

    func sendCommand(command: WebSocketCommand, completion: ((Error?) -> ())? = nil) {

        do {
            let jsonData = try JSONEncoder().encode(command)
            self.webSocket.write(data: jsonData, completion: { [weak self] in
                completion?(nil)
            })
        } catch (let error) {
            completion?(error)
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

        print("websocketDidReceiveMessage")

        guard let data = text.data(using: .utf8) else { return }
        do {

            let webSoketCommand = try JSONDecoder().decode(WebSocketCommand.self, from: data)

            switch webSoketCommand.data {
            case .success(let successWebSocketData):
                switch successWebSocketData {

                case .userInit( _ ):
                    break

                case .playListLoadTracks(let tracks):

//                    print("LoadTracksCommand: \(text)")

                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveTracks: tracks)
                    })

                case .playListUpdate(let playList):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceivePlayList: playList)
                    })

                case .currentTrackId(let trackId):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCurrentTrackId: trackId)
                    })

                case .currentTrackState(let trackState):
                    self.observersContainer.invoke({ (observer) in
                        observer.webSocketService(self, didReceiveCurrentTrackState: trackState)
                    })

                case .checkAddons(let checkAddons):
                    print("checkAddons: \(checkAddons)")

                case .playAddon(let addonState):
                    print("addinState: \(addonState)")
                }

            case .failure(let error):
                print(error)

            case .unknown:
                print("Unknown channel: \(webSoketCommand.channel) command: \(webSoketCommand.command)")
                print("websocketDidReceiveMessage: \(text)")
            }

        } catch (let error) {
            print(error.localizedDescription)
        }

    }

    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("websocketDidReceiveData")

        do {

            let decoded = try JSONSerialization.jsonObject(with: data, options: [])

            print("websocketDidReceiveData: \(decoded)")
        } catch {
            print(error.localizedDescription)
        }

    }
}
