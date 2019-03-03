//
//  PlayerContentContainerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlayerContentContainerViewController: UITabBarController {

    // MARK: - Public properties -

    private(set) var viewModel: PlayerContentContainerViewModel!
    private(set) var router: FlowRouter!
    // MARK: - Configuration -

    func configure(viewModel: PlayerContentContainerViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }
}

// MARK: - Router -
extension PlayerContentContainerViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension PlayerContentContainerViewController: PlayerContentContainerViewModelDelegate {

    func refreshUI() {

    }

}
