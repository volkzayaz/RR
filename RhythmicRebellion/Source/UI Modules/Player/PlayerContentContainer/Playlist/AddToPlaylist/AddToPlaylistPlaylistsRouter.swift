//
//  AddToPlaylistRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AddToPlaylistRouter: FlowRouter {
    func dismiss()
}

final class DefaultAddToPlaylistRouter:  AddToPlaylistRouter, SegueCompatible {

    typealias Destinations = SegueList

    enum SegueList: String, SegueDestinations {
        case placeholder

        var identifier: String {
            switch self {
            case .placeholder: return "placeholder"
            }
        }

        static func from(identifier: String) -> SegueList? {
            switch identifier {
            case "placeholder" : return .placeholder
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies
    
    private(set) weak var viewModel: AddToPlaylistViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        default:
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: AddToPlaylistViewController, track: Track) {
        sourceController = controller
        let vm = AddToPlaylistControllerViewModel(router: self, restApiService: self.dependencies.restApiService, track: track)
        controller.configure(viewModel: vm, router: self)
    }
    
    func dismiss() {
        self.sourceController?.dismiss(animated: true, completion: nil)
    }
}
