//
//  ProfileRouter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ProfileRouter: FlowRouter {
}

final class DefaultProfileRouter:  ProfileRouter, SegueCompatible {

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
            default: return nil
            }
        }
    }

    private(set) var dependencies: RouterDependencies

    private(set) weak var viewModel: ProfileViewModel?
    private(set) weak var sourceController: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let payload = merge(segue: segue, with: sender) else { return }

        switch payload {
        case .placeholder:
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: ProfileViewController) {
        sourceController = controller
        let vm = ProfileControllerViewModel(router: self, application: self.dependencies.application)
        controller.configure(viewModel: vm, router: self)
    }
}