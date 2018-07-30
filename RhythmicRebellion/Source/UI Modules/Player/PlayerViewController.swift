//
//  PlayerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

enum PlayerNavigationItemType: Int {
    case follow
    case video
    case lirycs
    case playList
    case promo
}

class PlayerNavigationItem {

    var type: PlayerNavigationItemType

    private weak var playerViewController: PlayerViewController?

    fileprivate init?(playerViewController: PlayerViewController, tag: Int) {
        guard let type = PlayerNavigationItemType.init(rawValue: tag) else { return nil }

        self.type = type
        self.playerViewController = playerViewController
    }

    deinit {
        self.playerViewController?.unselect(self)
    }
}

protocol PlayerNavigationDelgate: class {
    func navigate(to playerNavigationItem: PlayerNavigationItem)
}

final class PlayerViewController: UIViewController {

    // MARK: - Outlet properties -
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
    private(set) var navigationDelegate: PlayerNavigationDelgate!

    // MARK: - Configuration -

    func configure(viewModel: PlayerViewModel, router: FlowRouter, navigationDelegate: PlayerNavigationDelgate) {
        self.viewModel = viewModel
        self.router    = router
        self.navigationDelegate = navigationDelegate
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

    func tabBarItem(with playerNavigationItemType: PlayerNavigationItemType, on tabBar: UITabBar) -> UITabBarItem? {
        return tabBar.items?.filter({
            guard let tabBarItemNavigationItemType = PlayerNavigationItemType(rawValue: $0.tag),
                tabBarItemNavigationItemType == playerNavigationItemType else { return false }
            return true
        }).first
    }

    func unselect(_ playerNavigationItem: PlayerNavigationItem) {

        switch playerNavigationItem.type {
        case .follow:

            self.compactFollowButton.isSelected = false
            self.compactFollowButton.tintColor = #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1)

            if let regularTabBarSelectedItem = self.regularTabBar.selectedItem,
                let regularPlayerNavigationItemType = PlayerNavigationItemType(rawValue: regularTabBarSelectedItem.tag),
                playerNavigationItem.type == regularPlayerNavigationItemType {

                self.regularTabBar.selectedItem = nil
            }

        default:
            if let compactTabBarSelectedItem = self.compactTabBar.selectedItem,
                let compactPlayerNavigationItemType = PlayerNavigationItemType(rawValue: compactTabBarSelectedItem.tag),
                playerNavigationItem.type == compactPlayerNavigationItemType {

                self.compactTabBar.selectedItem = nil
            }

            if let regularTabBarSelectedItem = self.regularTabBar.selectedItem,
                let regularPlayerNavigationItemType = PlayerNavigationItemType(rawValue: regularTabBarSelectedItem.tag),
                playerNavigationItem.type == regularPlayerNavigationItemType {

                self.regularTabBar.selectedItem = nil
            }
        }

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

    @IBAction func onFollowCompactButton(sender: UIButton) {
        guard let navigationItem = PlayerNavigationItem(playerViewController: self, tag: 0) else { return }

        self.compactFollowButton.isSelected = true
        self.compactFollowButton.tintColor = #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 1)

        self.regularTabBar.selectedItem = self.tabBarItem(with: .follow, on: self.regularTabBar)

        self.navigationDelegate.navigate(to: navigationItem)
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

// MARK: - ViewModel -

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

// MARK: - UITabBarDelegate

extension PlayerViewController: UITabBarDelegate {

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let navigationItem = PlayerNavigationItem(playerViewController: self, tag: item.tag) else { return }


        if tabBar == self.compactTabBar {
            self.regularTabBar.selectedItem = self.tabBarItem(with: navigationItem.type, on: self.regularTabBar)
        } else {
            switch navigationItem.type {
            case .follow:
                self.compactFollowButton.isSelected = true
                self.compactFollowButton.tintColor = #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 1)

            default:
                self.compactTabBar.selectedItem = self.tabBarItem(with: navigationItem.type, on: self.compactTabBar)
            }
        }

        self.navigationDelegate.navigate(to: navigationItem)
    }
}
