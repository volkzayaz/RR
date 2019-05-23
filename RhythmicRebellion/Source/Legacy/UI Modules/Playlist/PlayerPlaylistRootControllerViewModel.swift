//
//  PlayerPlaylistRootControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxCocoa

struct PlayerPlaylistRootViewModel {

    private(set) weak var router: PlayerPlaylistRootRouter?

    init(router: PlayerPlaylistRootRouter) {
        self.router = router
    }
    
    var showOnlyNowPlaying: Driver<Bool> {
        return appState.map { $0.user.isGuest }
                       .distinctUntilChanged()
    }
}

