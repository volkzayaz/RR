//
//  FakeWebSocketService.swift
//  RhythmicRebellionTests
//
//  Created by Andrey Ivanov on 5/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import RxSwift

@testable import RhythmicRebellion

class FakeWebSocketService: WebSocketService {
    
    override var didReceiveTracks: Observable<[Track]> {
        return .just([])
    }
    
    override func filter(addons: [Addon], for track: Track) -> Observable<[Addon]> {
        return .just(addons)
    }
    
    override func markPlayed(addon: Addon, for track: Track) {
        
    }
    
    override func fetchTracks(trackIds: [Int]) -> Observable<[Track]> {
        return .just(Tracks.all.filter { trackIds.contains($0.id) })
    }
}
