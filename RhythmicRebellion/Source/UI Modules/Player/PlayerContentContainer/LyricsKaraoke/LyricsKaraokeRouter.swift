//
//  LyricsKaraokeContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol LyricsKaraokeRouterDelegate: ForcedAuthorizationRouter {

}

protocol LyricsKaraokeRouter: FlowRouter {
    func routeToLyrics()
    func routeToKaraoke()
}

final class DefaultLyricsKaraokeRouter:  LyricsKaraokeRouter, FlowRouterSegueCompatible {


    typealias DestinationsList = SegueList
    typealias Destinations = SegueActions

    enum SegueList: String, SegueDestinationList {
        case lyrisc = "LyricsSegueIdentifier"
        case karaoke = "KaraokeSegueIdentifier"
    }

    enum SegueActions: SegueDestinations {
        case showLyrics
        case showKaraoke

        var identifier: SegueDestinationList {
            switch self {
            case .showLyrics: return SegueList.lyrisc
            case .showKaraoke: return SegueList.karaoke
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    private(set) weak var delegate: LyricsKaraokeRouterDelegate?

    private(set) weak var viewModel: LyricsKaraokeViewModel?
    private(set) weak var viewController: LyricsKaraokeViewController?

    var sourceController: UIViewController? { return viewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultLyricsKaraokeRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .showLyrics:
            guard let lyricsViewController = segue.destination as? LyricsViewController else { fatalError("Incorrect controller for LyricsSegueIdentifier") }
            let lyricsRouter = DefaultLyricsRouter(dependencies: self.dependencies, delegate: self)
            lyricsRouter.start(controller: lyricsViewController)

        case .showKaraoke:
            guard let karaokeViewController = segue.destination as? KaraokeViewController else { fatalError("Incorrect controller for KaraokeSegueIdentifier") }
            let karaokeRouter = DefaultKaraokeRouter(dependencies: self.dependencies)
            karaokeRouter.start(controller: karaokeViewController)
        }
    }

    init(dependencies: RouterDependencies, delegate: LyricsKaraokeRouterDelegate?) {
        self.dependencies = dependencies
        self.delegate = delegate
    }

    func start(controller: LyricsKaraokeViewController) {
        viewController = controller
        let vm = LyricsKaraokeViewModel(router: self, player: self.dependencies.player)
        controller.configure(viewModel: vm, router: self)
    }

    func routeToLyrics() {
        guard let viewController = self.viewController else { return }
        guard viewController.currentViewController as? LyricsViewController == nil else { return }

        self.perform(segue: .showLyrics)
    }

    func routeToKaraoke() {
        guard let viewController = self.viewController else { return }
        guard viewController.currentViewController as? KaraokeViewController == nil else { return }

        self.perform(segue: .showKaraoke)
    }
}

extension DefaultLyricsKaraokeRouter: LyricsRouterDelegate {
    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.delegate?.routeToAuthorization(with: authorizationType)
    }
}
