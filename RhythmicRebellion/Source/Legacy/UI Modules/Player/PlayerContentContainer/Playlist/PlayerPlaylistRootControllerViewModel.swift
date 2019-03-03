//
//  PlayerPlaylistRootControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/26/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class PlayerPlaylistRootControllerViewModel: PlayerPlaylistRootViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerPlaylistRootViewModelDelegate?
    private(set) weak var router: PlayerPlaylistRootRouter?

    private let application : Application
    // MARK: - Lifecycle -

    init(router: PlayerPlaylistRootRouter, application: Application) {
        self.router = router
        self.application = application
    }

    func load(with delegate: PlayerPlaylistRootViewModelDelegate) {
        self.delegate = delegate
        application.addWatcher(self)
    }
    
    var showOnlyNowPlaying: Bool {
        return application.user?.isGuest ?? true
    }
}

extension PlayerPlaylistRootControllerViewModel : ApplicationWatcher {
    func application(_ application: Application, didChange user: User) {
        self.delegate?.refreshUI()
    }
}
