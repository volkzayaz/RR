//
//  AddToPlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class AddToPlaylistRouter {

    private(set) weak var sourceController: UIViewController?

    func start(controller: AddToPlaylistViewController, tracks: [Track]) {
        sourceController = controller
        let vm = AddTracksToPlaylistControllerViewModel(router: self, tracks: tracks)
        controller.viewModel = vm
    }

    func start(controller: AddToPlaylistViewController, playlist: Playlist) {
        sourceController = controller
        let vm = AddPlaylistToPlaylistControllerViewModel(router: self, playlist: playlist)
        controller.viewModel = vm
    }

    
    func dismiss() {
        self.sourceController?.dismiss(animated: true, completion: nil)
    }
}
