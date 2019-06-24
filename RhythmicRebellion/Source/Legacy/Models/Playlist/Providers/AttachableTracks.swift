//
//  AttachableTracks.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/24/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift

extension Array: AttachableProvider where Element == Track {
    
    func attach(to playlist: FanPlaylist) -> Maybe<Void> {
        return PlaylistRequest.attachTracks(self, to: playlist)
            .rx.emptyResponse()
    }
    
}
