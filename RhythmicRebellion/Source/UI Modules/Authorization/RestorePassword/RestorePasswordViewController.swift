//
//  RestorePasswordViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class RestorePasswordViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: RestorePasswordViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: RestorePasswordViewModel, router: FlowRouter) {
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
extension RestorePasswordViewController {

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

extension RestorePasswordViewController: RestorePasswordViewModelDelegate {

    func refreshUI() {

    }

}
