//
//  PageContentRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/15/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PageContentRouterDelegate: ForcedAuthorizationRouter {
    func pageFailed(with error: Error)
}

protocol PageContentRouter: FlowRouter {
    func navigateToAuthorization()
    func pageFailed(with error: Error)
    func showDownloadAlbum(album: Album)
}

final class DefaultPageContentRouter:  PageContentRouter, FlowRouterSegueCompatible {

    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case placeholder = "placeholder"
    }

    enum SegueActions: SegueDestinations {
        case placeholder

        var identifier: SegueDestinationList {
            switch self {
            case .placeholder: return SegueList.placeholder
            }
        }
    }

    private(set) weak var viewModel: PageContentViewModel?
    private(set) weak var sourceController: UIViewController?

    private(set) var dependencies: RouterDependencies
    private(set) weak var delegate: PageContentRouterDelegate?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultPageContentRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .placeholder: break
        }
    }

    init(dependencies: RouterDependencies, delegate: PageContentRouterDelegate?) {
        self.dependencies = dependencies
        self.delegate = delegate
    }

    func start(controller: PageContentViewController, page: Page) {
        sourceController = controller
        let vm = PageContentControllerViewModel(router: self, page: page, pagesLocalStorage: self.dependencies.daPlayer.pagesLocalStorageService)
        controller.configure(viewModel: vm, router: self)
    }

    func pageFailed(with error: Error) {
        self.delegate?.pageFailed(with: error)
    }

    func navigateToAuthorization() {
        self.delegate?.routeToAuthorization(with: .signIn)
    }
    
    func showDownloadAlbum(album: Album) {
        let vc = R.storyboard.main.playlistViewController()!
        vc.viewModel = PlaylistViewModel(router: PlaylistRouter(owner: vc),
                                         provider: AlbumPlaylistProvider(album: album,
                                                                         instantDownload: true))

        sourceController?.navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
