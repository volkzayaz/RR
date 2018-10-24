//
//  ChangeEmailViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class ChangeEmailViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: ChangeEmailViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: ChangeEmailViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router

        if self.isViewLoaded {
            self.bindViewModel()
        }
    }

    func bindViewModel() {
        viewModel.load(with: self)
    }


    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.bindViewModel()
    }

}

// MARK: - Router -
extension ChangeEmailViewController {

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

extension ChangeEmailViewController: ChangeEmailViewModelDelegate {

    func refreshUI() {

    }

}
