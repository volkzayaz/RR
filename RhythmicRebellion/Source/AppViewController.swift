//
//  AppViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class AppViewController: UIViewController {

    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var playerContainerViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var playerDisclosureButton: UIButton!

    // MARK: - Public properties -

    private(set) var viewModel: AppViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: AppViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

    // MARK: - Actions -
    @IBAction func onPlayerDisclosureButton(sender: UIButton) {
        self.viewModel.togglePlayerDisclosure()
    }

}

// MARK: - Router -
extension AppViewController {

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

extension AppViewController: AppViewModelDelegate {

    func refreshUI() {

    }

    func playerDisclosureStateChanged(isDisclosed: Bool) {

        let playerMenuButtonImageViewTransform = isDisclosed ? CGAffineTransform(rotationAngle: .pi) : CGAffineTransform(rotationAngle: .pi - 3.14159)
        let playerMenuButtonBackgroundColor = isDisclosed ?  #colorLiteral(red: 0.07252354175, green: 0.03960485011, blue: 0.2421343923, alpha: 1) : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
        let playerMenuButtonTintColor = isDisclosed ? #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1) : #colorLiteral(red: 0.07252354175, green: 0.03960485011, blue: 0.2421343923, alpha: 1)
        self.playerContainerViewHeightConstraint?.constant = isDisclosed ? 118.0 : 74

        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
            self.playerDisclosureButton?.imageView?.transform = playerMenuButtonImageViewTransform
            self.playerDisclosureButton?.backgroundColor = playerMenuButtonBackgroundColor
            self.playerDisclosureButton?.tintColor = playerMenuButtonTintColor
        }, completion: nil)
    }

}
