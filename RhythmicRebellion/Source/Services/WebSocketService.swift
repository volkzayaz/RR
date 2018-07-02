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
    var token: String?

    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "WebSocketService")

    init(with url: URL) {

        var request = URLRequest(url: url)
        request.timeoutInterval = 1

        self.webSocket = WebSocket(request: request)
        self.webSocket.delegate = self
    }

    func connect(with token: String) {
        self.token = token

        print("Connect with token: \(token)")

        self.webSocket.connect()
    }

    // MARK: - WebSocketDelegate -
    public func websocketDidConnect(socket: WebSocketClient) {
        print("websocketDidConnect")

        let data = ["isGuest" : true, "token" : self.token!] as [String : Any]
        let initInfo = ["channel" : "user", "cmd" : "init", "data" : data] as [String : Any]


        do {
            let jsonData = try JSONSerialization.data(withJSONObject: initInfo, options: .prettyPrinted)
            self.webSocket.write(data: jsonData)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("websocketDidDisconnect: \(error)")
    }

    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {

        guard let data = text.data(using: .utf8) else { return }
        do {

            let command = try JSONDecoder().decode(Command.self, from: data)
            switch command {
            case .playListLoadTracks(let traks):
                self.observersContainer.invoke({ (observer) in
                    observer.webSocketService(self, didReceiveTracks: traks)
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
            case .unknown:
                print("Unknown command: \(text)")
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
