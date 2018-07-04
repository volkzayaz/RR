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

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track])
    func webSocketService(_ service: WebSocketService, didReceivePlayList playList: [String: PlayListItem])
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId)
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState)
}

extension WebSocketServiceObserver {

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) { }
    func webSocketService(_ service: WebSocketService, didReceivePlayList playList: [String: PlayListItem]) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId) { }
    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) { }

}

class WebSocketService: WebSocketDelegate, Observable {

    typealias ObserverType = WebSocketServiceObserver

    let observersContainer = ObserversContainer<WebSocketServiceObserver>()

    var webSocket: WebSocket
    var token: Token?

    var trackStateSendDate = Date()

    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "WebSocketService")

    init(with url: URL) {

        var request = URLRequest(url: url)
        request.timeoutInterval = 1

        self.webSocket = WebSocket(request: request)
        self.webSocket.delegate = self
    }

    func connect(with token: Token) {
        self.token = token

        print("self.token: \(self.token)")

        self.webSocket.connect()
    }

    func sendCommand(command: WebSocketCommand, completion: ((Error?) -> ())? = nil) {

        do {
            let jsonData = try JSONEncoder().encode(command)
            self.webSocket.write(data: jsonData, completion: { [weak self] in

                if command.commandType == .currentTrackState {
                    self?.trackStateSendDate = Date()
                }


                completion?(nil)
            })
        } catch (let error) {
            completion?(error)
        }
    }

    // MARK: - WebSocketDelegate -
    public func websocketDidConnect(socket: WebSocketClient) {
        guard let token = self.token else { return }
        let initialCommand = WebSocketCommand.initialCommand(token: token)
        self.sendCommand(command: initialCommand)
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect: \(String(describing: error))")

        self.webSocket.connect()

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
                    if Date().timeIntervalSince(self.trackStateSendDate) > 1.0 {
                        self.observersContainer.invoke({ (observer) in
                            observer.webSocketService(self, didReceiveCurrentTrackState: trackState)
                        })
                    }
                }
            case .faile(let error):
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
