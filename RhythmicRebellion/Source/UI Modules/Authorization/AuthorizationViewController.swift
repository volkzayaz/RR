//
//  AuthorizationViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class AuthorizationViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var segmentedControl: UISegmentedControl!

    // MARK: - Public properties -

    private(set) var viewModel: AuthorizationViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: AuthorizationViewModel, router: FlowRouter) {
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
extension AuthorizationViewController {

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

extension AuthorizationViewController: AuthorizationViewModelDelegate {

    func refreshUI() {

    }

}
