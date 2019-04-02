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

    private let application : Application
    // MARK: - Lifecycle -

    init(router: PlayerPlaylistRootRouter, application: Application) {
        self.router = router
        self.application = application
    }
    
    var showOnlyNowPlaying: Driver<Bool> {
        return appState.map { $0.user == nil }
                       .distinctUntilChanged()
    }
}

