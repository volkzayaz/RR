//
//  PlaylistManager.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/3/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

enum PlaylistManager {}
extension PlaylistManager {
    
    static func createPlaylist(with name: String) -> Maybe<FanPlaylist> {
        return PlaylistRequest.create(name: name)
            .rx.response(type: FanPlaylist.self)
            .do(onNext: { playlist in
                
                let fanPlaylistState = FanPlaylistState(id: playlist.id, playlist: playlist)
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: fanPlaylistState))
                
            })
    }
    
    static func delete(playlist: FanPlaylist) -> Maybe<Void> {
        return PlaylistRequest.delete(playlist: playlist)
            .rx.emptyResponse()
            .do(onNext: {
                
                let fanPlaylistState = FanPlaylistState(id: playlist.id, playlist: nil)
                DataLayer.get.webSocketService.sendCommand(command: CodableWebSocketCommand(data: fanPlaylistState))
                
                Dispatcher.dispatch(action: RemovePlaylist(playlist: playlist)) 
                
            })
    }
    
}
