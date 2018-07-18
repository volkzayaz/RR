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

    @IBOutlet var blockOverlayView: UILabel!

    @IBOutlet weak var playerItemNameLabel: UILabel!
    @IBOutlet weak var playerItemNameSeparatorLabel: UILabel!
    @IBOutlet weak var playerItemArtistNameLabel: UILabel!

    @IBOutlet weak var playerItemCurrentTimeLabel: UILabel!
    @IBOutlet weak var playerItemDurationLabel: UILabel!

    @IBOutlet weak var playerItemProgressView: UIProgressView!

    @IBOutlet weak var compactTabBar: UITabBar!
    @IBOutlet weak var regularTabBar: TabBarRegular!

    @IBOutlet weak var compactFollowButton: UIButton!

    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet var playBarButtonItem: UIBarButtonItem!
    @IBOutlet var pauseBarButtonItem: UIBarButtonItem!

    @IBOutlet var forwardBarButtonItem: UIBarButtonItem!
    @IBOutlet var backwardBarButtonItem: UIBarButtonItem!

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

        if self.viewModel.isPlayerBlocked == true && self.blockOverlayView.superview == nil {

            self.blockOverlayView.frame = self.view.bounds
            self.view.addSubview(self.blockOverlayView)

            NSLayoutConstraint.activate([self.blockOverlayView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                         self.blockOverlayView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                         self.blockOverlayView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                         self.blockOverlayView.rightAnchor.constraint(equalTo: self.view.rightAnchor)])

        } else if self.viewModel.isPlayerBlocked == false && self.blockOverlayView.superview != nil {

            self.blockOverlayView.removeFromSuperview()
        }

        self.playerItemNameLabel.text = self.viewModel.playerItemNameString
        self.playerItemArtistNameLabel.text = self.viewModel.playerItemArtistNameString

        self.playerItemNameSeparatorLabel.isHidden = self.playerItemNameLabel.text?.isEmpty ?? true || self.playerItemArtistNameLabel.text?.isEmpty ?? true

        self.playerItemDurationLabel.text = self.viewModel.playerItemDurationString

        self.forwardBarButtonItem.isEnabled = self.viewModel.canForward
        self.backwardBarButtonItem.isEnabled = self.viewModel.canBackward

        self.refreshProgressUI()
    }

    func refreshProgressUI() {
        self.playerItemCurrentTimeLabel.text = self.viewModel.playerItemCurrentTimeString
        self.playerItemProgressView.progress = self.viewModel.playerItemProgress
        self.updatePlayPauseState()
    }
}
