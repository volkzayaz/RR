//
//  LyricsKaraokeContainerRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class LyricsKaraokeRouter: FlowRouterSegueCompatible {

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
    
    private(set) weak var viewController: LyricsKaraokeViewController?

    var sourceController: UIViewController? { return viewController }

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for destination: LyricsKaraokeRouter.SegueActions, segue: UIStoryboardSegue) {

        switch destination {
        case .showLyrics:
            guard let lyricsViewController = segue.destination as? LyricsViewController else { fatalError("Incorrect controller for LyricsSegueIdentifier") }
            lyricsViewController.viewModel = .init(router: LyricsRouter(owner: lyricsViewController))
            
        case .showKaraoke:
            guard let karaokeViewController = segue.destination as? KaraokeViewController else { fatalError("Incorrect controller for KaraokeSegueIdentifier") }
            let karaokeRouter = DefaultKaraokeRouter()
            karaokeRouter.start(controller: karaokeViewController)
        }
    }

    init(owner: LyricsKaraokeViewController?) {
        
        self.viewController = owner
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
