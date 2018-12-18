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

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        print("willMove toParentViewController: \(parent)")
    }

    override func targetViewController(forAction action: Selector, sender: Any?) -> UIViewController? {

        print("targetViewController action: \(action) sender: \(sender)")

        return super.targetViewController(forAction: action, sender: sender)
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
