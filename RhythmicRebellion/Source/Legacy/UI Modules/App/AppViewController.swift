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

    @IBOutlet weak var contentContainerView: UIView!
    @IBOutlet weak var playerContainerView: UIView!
    @IBOutlet weak var playerContainerViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var playerDisclosureButton: UIButton!

    weak var contentContainerViewController: ApplicationContentContainerViewController?

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
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        if (motion == .motionShake)
        {
            UIAlertView(title: "Info", message: "Current Environent: \(SettingsStore.environment.value)"
            , delegate: nil, cancelButtonTitle: "Ok").show()
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {

        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.horizontalSizeClass == .compact {
            self.playerContainerViewHeightConstraint?.constant = self.viewModel.isPlayerDisclosed ? 126.0 : 81.0
            self.view.setNeedsUpdateConstraints()
        }
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()

        if self.traitCollection.horizontalSizeClass == .compact {
            self.playerContainerViewHeightConstraint?.constant = self.viewModel.isPlayerDisclosed ? 126.0 : 81.0
        }
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
        let playerMenuButtonBackgroundColor = isDisclosed ?  #colorLiteral(red: 0.05882352941, green: 0.02352941176, blue: 0.1843137255, alpha: 1) : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)
        let playerMenuButtonTintColor = isDisclosed ? #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1) : #colorLiteral(red: 0.05882352941, green: 0.02352941176, blue: 0.1843137255, alpha: 1)
        self.playerContainerViewHeightConstraint?.constant = isDisclosed ? 126.0 : 81.0

        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
            self.playerDisclosureButton?.imageView?.transform = playerMenuButtonImageViewTransform
            self.playerDisclosureButton?.backgroundColor = playerMenuButtonBackgroundColor
            self.playerDisclosureButton?.tintColor = playerMenuButtonTintColor
        }, completion: nil)
    }

}
