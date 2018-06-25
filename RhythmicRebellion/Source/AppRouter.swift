//
//  AppRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AppRouter: FlowRouter {
}

final class DefaultAppRouter:  AppRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case player

        var identifier: String {
            switch self {
            case .player: return "PlayerSegueIdentifier"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "PlayerSegueIdentifier": return .player
            default: return nil
            }
        }
    }

    private(set) weak var viewModel: AppViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .player:
            guard let playerViewController = segue.destination as? PlayerViewController else { fatalError("Incorrect controller for PlayerSegueIdentifier") }
            let playerRouter = DefaultPlayerRouter()
            playerRouter.start(controller: playerViewController)
            break
        }
    }

    init() {

    }

    func start(controller: AppViewController) {
        sourceController = controller
        let vm = AppControllerViewModel(router: self)
        controller.configure(viewModel: vm, router: self)
    }
}
