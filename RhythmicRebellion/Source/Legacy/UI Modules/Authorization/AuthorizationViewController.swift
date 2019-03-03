//
//  AuthorizationViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum AuthorizationSegment: Int {
    case signIn
    case signUp
}

final class AuthorizationViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!

    // MARK: - Public properties -

    private(set) var viewModel: AuthorizationViewModel!
    private(set) var router: FlowRouter!

    weak var selectedViewController: (UIViewController & AuthorizationChildViewController)? {
        didSet {
            guard let selectedViewController = self.selectedViewController else { segmentedControl.selectedSegmentIndex = -1; return }
            switch selectedViewController.authorizationType{
            case .signIn: self.segmentedControl.selectedSegmentIndex = AuthorizationSegment.signIn.rawValue
            case .signUp: self.segmentedControl.selectedSegmentIndex = AuthorizationSegment.signUp.rawValue
            }
        }
    }

    // MARK: - Configuration -

    func configure(viewModel: AuthorizationViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        self.viewModel.load(with: self)
    }

    // MARK: - Acitions -
    @IBAction func segmentedControlChanged(sender: UISegmentedControl) {
        guard let authorizationType = AuthorizationType.init(rawValue: segmentedControl.selectedSegmentIndex) else { return }

        self.viewModel.change(authorizationType: authorizationType)
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
