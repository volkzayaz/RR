//
//  PlayerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlayerViewController: UIViewController {

    @IBOutlet weak var playerItemDescriptionLabel: UILabel!

    @IBOutlet weak var playerItemProgressTimeLabel: UILabel!
    @IBOutlet weak var playerItemFullTimeLabel: UILabel!

    @IBOutlet weak var playerItemProgressView: UIProgressView!

    @IBOutlet weak var compactTabBar: UITabBar!
    @IBOutlet weak var regularTabBar: TabBarRegular!

    @IBOutlet weak var compactFollowButton: UIButton!


    @IBOutlet weak var toolBar: UIToolbar!

    // MARK: - Public properties -

    private(set) var viewModel: PlayerViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PlayerViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.playerItemDescriptionLabel.numberOfLines = self.traitCollection.horizontalSizeClass == .regular ? 2 : 1

    }
}

// MARK: - Router -
extension PlayerViewController {

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

extension PlayerViewController: PlayerViewModelDelegate {

    func refreshUI() {

    }

}
