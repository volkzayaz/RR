//
//  TabBarViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class TabBarViewController: UITabBarController {

    // MARK: - Public properties -

    private(set) var viewModel: TabBarViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: TabBarViewModel, router: FlowRouter, viewControllers: [UIViewController]) {
        self.viewModel = viewModel
        self.router    = router

        self.viewControllers = viewControllers
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

}

// MARK: - Router -
extension TabBarViewController {

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

extension TabBarViewController: TabBarViewModelDelegate {

    func refreshUI() {

    }

}
