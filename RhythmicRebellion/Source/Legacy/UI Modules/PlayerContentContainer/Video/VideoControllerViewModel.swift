//
//  VideoControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class VideoControllerViewModel: VideoViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: VideoViewModelDelegate?
    private(set) weak var router: VideoRouter?

    // MARK: - Lifecycle -

    init(router: VideoRouter) {
        self.router = router
    }

    func load(with delegate: VideoViewModelDelegate) {
        self.delegate = delegate
    }
}
