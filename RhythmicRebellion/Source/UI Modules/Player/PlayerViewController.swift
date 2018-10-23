//
//  PlayerViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import EasyTipView

final class PlayerViewController: UIViewController {

    // MARK: - Outlet properties -
    @IBOutlet var blockOverlayView: UILabel!

    @IBOutlet weak var playerItemNameLabel: UILabel!
    @IBOutlet weak var playerItemNameSeparatorLabel: UILabel!
    @IBOutlet weak var playerItemArtistNameLabel: UILabel!

    @IBOutlet weak var playerItemCurrentTimeLabel: UILabel!
    @IBOutlet weak var playerItemDurationLabel: UILabel!

    @IBOutlet weak var playerItemProgressView: ProgressView!
    @IBOutlet weak var playerItemProgressViewTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet var playerItemPreviewOptionButton: UIButton!

    @IBOutlet weak var compactTabBar: UITabBar!

    @IBOutlet weak var compactFollowButton: UIButton!
    @IBOutlet weak var regularFollowButton: UIButton!

    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var lyricsButton: UIButton!
    @IBOutlet weak var playlistButton: UIButton!
    @IBOutlet weak var promoButton: UIButton!

    var playerContentButtons: [UIButton]!

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

        var tipViewPreferences = EasyTipView.Preferences()
        tipViewPreferences.drawing.font = UIFont.systemFont(ofSize: 12.0)
        tipViewPreferences.drawing.foregroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        tipViewPreferences.drawing.backgroundColor = #colorLiteral(red: 0.2089539468, green: 0.1869146228, blue: 0.349752754, alpha: 1)
        tipViewPreferences.animating.showInitialAlpha = 0
        tipViewPreferences.animating.showDuration = 1.5
        tipViewPreferences.animating.dismissDuration = 1.5
        tipViewPreferences.positioning.textHInset = 5.0
        tipViewPreferences.positioning.textVInset = 5.0
        EasyTipView.globalPreferences = tipViewPreferences

        self.toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
        self.toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)

        self.regularFollowButton.setTitle(self.regularFollowButton.title(for: .normal), for: [.normal, .highlighted])
        self.regularFollowButton.setTitleColor(self.regularFollowButton.titleColor(for: .normal), for: [.normal, .highlighted])
        self.regularFollowButton.setTitle(self.regularFollowButton.title(for: .selected), for: [.selected, .highlighted])
        self.regularFollowButton.setTitleColor(self.regularFollowButton.titleColor(for: .selected), for: [.selected, .highlighted])

        self.playerContentButtons = [self.videoButton, self.lyricsButton, self.playlistButton, self.promoButton]

        self.playerItemProgressView.setThumbImage(UIImage(named: "ProgressIndicator")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.playerItemProgressView.setThumbImage(UIImage(named: "ProgressIndicator")?.withRenderingMode(.alwaysTemplate), for: .highlighted)

        self.playerItemProgressViewTapGestureRecognizer.delegate = self

        viewModel.load(with: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.startObserve()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        viewModel.stopObserve()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.refreshUI()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { (context) in
            self.refreshUI()
        }
    }

    func tabBarItem(with playerNavigationItemType: PlayerNavigationItemType, on tabBar: UITabBar) -> UITabBarItem? {
        return tabBar.items?.filter({
            guard let tabBarItemNavigationItemType = PlayerNavigationItemType(rawValue: $0.tag),
                tabBarItemNavigationItemType == playerNavigationItemType else { return false }
            return true
        }).first
    }

    func unselect(_ playerNavigationItem: PlayerNavigationItem) {

        if compactTabBar.selectedItem?.tag == playerNavigationItem.type.rawValue {
            self.compactTabBar.selectedItem = nil
        }

        switch playerNavigationItem.type {
        case .video: self.videoButton.isSelected = false
        case .lyrics: self.lyricsButton.isSelected = false
        case .playlist: self.playlistButton.isSelected = false
        case .promo: self.promoButton.isSelected = false
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

    @IBAction func onFollowButton(sender: UIButton) {
        viewModel.toggleArtistFollowing()
    }

    @IBAction func onPlayerContentButton(sender: UIButton) {

        sender.isSelected = true

        switch sender {
        case self.videoButton: self.viewModel.navigate(to: .video)
        case self.lyricsButton: self.viewModel.navigate(to: .lyrics)
        case self.playlistButton: self.viewModel.navigate(to: .playlist)
        case self.promoButton: self.viewModel.navigate(to: .promo)

        default: break
        }
    }

    @IBAction func playerItemProgressViewValueChanged(sender: UISlider) {
        self.viewModel.setPlayerItemProgress(progress: sender.value)
    }

    @IBAction func playerItemProgressViewTapGestureRecognizer(sender: UITapGestureRecognizer) {

        guard self.playerItemProgressView.isTracking == false else { return }

        let location = sender.location(in: sender.view)
        let bounds = self.playerItemProgressView.bounds
        let value = Float(location.x / bounds.width)

        self.viewModel.setPlayerItemProgress(progress: value)
    }

    @IBAction func onPlayerItemPreviewOptionButton(sender: UIButton) {
        guard let parentView = self.parent?.view, let previewOptionHintText = self.viewModel.playerItemPreviewOptionViewModel?.hintText, previewOptionHintText.isEmpty == false else { return }

        let tipView = TipView(text: previewOptionHintText, preferences: EasyTipView.globalPreferences)
        tipView.showTouched(forView: sender, withinSuperview: parentView)
    }
}

// MARK: - UIGestureRecognizerDelegate -

extension PlayerViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        switch gestureRecognizer {
        case self.playerItemProgressViewTapGestureRecognizer: return self.playerItemProgressView.isTracking == false
        default: return true
        }
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

        self.playerItemProgressView.isUserInteractionEnabled = self.viewModel.canSetPlayerItemProgress

        self.regularFollowButton.isSelected = self.viewModel.isArtistFollowed
        self.compactFollowButton.isSelected = self.regularFollowButton.isSelected
        self.compactFollowButton.tintColor = self.regularFollowButton.tintColor

        self.playerItemPreviewOptionButton.setImage(self.viewModel.playerItemPreviewOptionViewModel?.image?.withRenderingMode(.alwaysTemplate), for: .normal)

        self.refreshProgressUI()
    }

    func refreshProgressUI() {

        self.playerItemProgressView.restrictedValue = self.viewModel.playerItemRestrictedValue

        self.playerItemCurrentTimeLabel.text = self.viewModel.playerItemCurrentTimeString
        if self.playerItemProgressView.isTracking == false {
            self.playerItemProgressView.setValue(self.viewModel.playerItemProgressValue, animated: true)
        }
        self.updatePlayPauseState()
    }
}

// MARK: - UITabBarDelegate

extension PlayerViewController: UITabBarDelegate {

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let navigationType = PlayerNavigationItemType.init(rawValue: item.tag) else { return }
        self.viewModel.navigate(to: navigationType)
    }
}
