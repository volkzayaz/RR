//
//  LyricsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class LyricsControllerViewModel: LyricsViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: LyricsViewModelDelegate?
    private(set) weak var router: LyricsRouter?

    // MARK: - Lifecycle -

    init(router: LyricsRouter) {
        self.router = router
    }

    func load(with delegate: LyricsViewModelDelegate) {
        self.delegate = delegate
    }
}
