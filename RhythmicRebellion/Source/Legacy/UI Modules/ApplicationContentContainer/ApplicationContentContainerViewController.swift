//
//  ApplicationContentContainerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class ApplicationContentContainerViewController: UIViewController {

    // MARK: - Public properties -

    var tabBarViewController: TabBarViewController!
    weak var playerContentContainerViewController: PlayerContentContainerViewController?

    private(set) var viewModel: ApplicationContentContainerViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: ApplicationContentContainerViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

    override func targetViewController(forAction action: Selector, sender: Any?) -> UIViewController? {

        return super.targetViewController(forAction: action, sender: sender)
    }
}

// MARK: - Router -
extension ApplicationContentContainerViewController {

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

extension ApplicationContentContainerViewController: ApplicationContentContainerViewModelDelegate {

    func refreshUI() {

    }

}


