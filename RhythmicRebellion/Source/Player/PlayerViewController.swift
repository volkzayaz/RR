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

    @IBOutlet weak var playerItemCurrentTimeLabel: UILabel!
    @IBOutlet weak var playerItemDurationLabel: UILabel!

    @IBOutlet weak var playerItemProgressView: UIProgressView!

    @IBOutlet weak var compactTabBar: UITabBar!
    @IBOutlet weak var regularTabBar: TabBarRegular!

    @IBOutlet weak var compactFollowButton: UIButton!

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet var playBarButtonItem: UIBarButtonItem!
    @IBOutlet var pauseBarButtonItem: UIBarButtonItem!

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.startObservePlayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.stopObservePlayer()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.playerItemDescriptionLabel.numberOfLines = self.traitCollection.horizontalSizeClass == .regular ? 2 : 1
        self.refreshUI()
    }

    // MARK: - Actions -
    @IBAction func onPlayButton(sender: UIBarButtonItem) {
        self.viewModel.play()
    }

    @IBAction func onPauseButton(sender: UIBarButtonItem) {
        viewModel.pause()
    }

    @IBAction func onForwardButton(sender: UIBarButtonItem) {
        viewModel.forward()
    }

    @IBAction func onBackwardButton(sender: UIBarButtonItem) {
        viewModel.backward()
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

    func updatePlayPauseState() {

        var playerToolBarItems = self.toolBar.items
        let playButtonIndex = playerToolBarItems?.index(of: self.playBarButtonItem)
        let pauseButtonIndex = playerToolBarItems?.index(of: self.pauseBarButtonItem)
        if self.viewModel.isPlaying {
            if pauseButtonIndex == nil && playButtonIndex != nil {
                playerToolBarItems?.remove(at: playButtonIndex!)
                playerToolBarItems?.insert(self.pauseBarButtonItem, at: playButtonIndex!)
            }
        } else {
            if pauseButtonIndex != nil && playButtonIndex == nil {
                playerToolBarItems?.remove(at: pauseButtonIndex!)
                playerToolBarItems?.insert(self.playBarButtonItem, at: pauseButtonIndex!)
            }
        }
        self.toolBar.items = playerToolBarItems

    }

    func refreshUI() {
        guard self.isViewLoaded == true else { return }

        self.playerItemDescriptionLabel.attributedText = self.viewModel.playerItemDescriptionAttributedText(for: self.traitCollection)
        self.playerItemDurationLabel.text = self.viewModel.playerItemDurationString

        self.refreshProgressUI()
    }

    func refreshProgressUI() {
        self.playerItemCurrentTimeLabel.text = self.viewModel.playerItemCurrentTimeString
        self.playerItemProgressView.progress = self.viewModel.playerItemProgress
        self.updatePlayPauseState()
    }
}
