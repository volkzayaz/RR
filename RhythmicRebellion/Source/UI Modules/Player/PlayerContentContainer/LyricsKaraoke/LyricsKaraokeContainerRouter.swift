//
//  LyricsKaraokeContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol LyricsKaraokeContainerRouterDelegate: ForcedAuthorizationRouter {

}

protocol LyricsKaraokeContainerRouter: FlowRouter {
    func routeToLyrics()
    func routeToKaraoke()
}

final class DefaultLyricsKaraokeContainerRouter:  LyricsKaraokeContainerRouter, FlowRouterSegueCompatible {


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
    private(set) weak var delegate: LyricsKaraokeContainerRouterDelegate?

    private(set) weak var viewModel: LyricsKaraokeContainerViewModel?
    private(set) weak var viewController: LyricsKaraokeContainerViewController?

    var sourceController: UIViewController? { return viewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: DefaultLyricsKaraokeContainerRouter.SegueActions, segue: UIStoryboardSegue) {

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

    init(dependencies: RouterDependencies, delegate: LyricsKaraokeContainerRouterDelegate?) {
        self.dependencies = dependencies
        self.delegate = delegate
    }

    func start(controller: LyricsKaraokeContainerViewController) {
        viewController = controller
        let vm = LyricsKaraokeContainerControllerViewModel(router: self, player: self.dependencies.player)
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

extension DefaultLyricsKaraokeContainerRouter: LyricsRouterDelegate {
    func routeToAuthorization(with authorizationType: AuthorizationType) {
        self.delegate?.routeToAuthorization(with: authorizationType)
    }
}
