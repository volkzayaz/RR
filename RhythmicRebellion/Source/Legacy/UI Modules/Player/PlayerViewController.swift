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
    @IBOutlet var likeBarButtonItem: UIBarButtonItem!
    @IBOutlet var dislikeBarButtonItem: UIBarButtonItem!

    // MARK: - Public properties -

    private(set) var viewModel: PlayerViewModel! {
        didSet {
            refreshUI()
        }
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.toolBar.setShadowImage(UIImage(), forToolbarPosition: .any)
        self.toolBar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)

        self.regularFollowButton.setTitle(self.regularFollowButton.title(for: .normal), for: [.normal, .highlighted])
        self.regularFollowButton.setTitleColor(self.regularFollowButton.titleColor(for: .normal), for: [.normal, .highlighted])
        self.regularFollowButton.setTitle(self.regularFollowButton.title(for: .selected), for: [.selected, .highlighted])
        self.regularFollowButton.setTitleColor(self.regularFollowButton.titleColor(for: .selected), for: [.selected, .highlighted])

        self.playerContentButtons = [self.videoButton, self.lyricsButton, self.playlistButton, self.promoButton]

        self.playerItemProgressView.setThumbImage(UIImage(named: "ProgressIndicator")?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.playerItemProgressView.setThumbImage(UIImage(named: "ProgressIndicator")?.withRenderingMode(.alwaysTemplate), for: [.normal, .highlighted])

        self.playerItemProgressView.setThumbImage(UIImage(named: "KaraokeProgressIndicator"), for: .selected)
        self.playerItemProgressView.setThumbImage(UIImage(named: "KaraokeProgressIndicator"), for: [.selected, .highlighted])


        self.playerItemProgressViewTapGestureRecognizer.delegate = self

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

    @IBAction func onLikeButton(sender: UIBarButtonItem) {
        self.viewModel.toggleLike()
    }

    @IBAction func onDislikeButton(sender: UIBarButtonItem) {
        self.viewModel.toggleDislike()
    }

    @IBAction func onFollowButton(sender: UIButton) {
        viewModel.toggleArtistFollowing()
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

// MARK: - ViewModel -

extension PlayerViewController {

    func updatePlayPauseState() {

        viewModel.isPlaying
            .drive(onNext: { [unowned self] (isPlaying) in
                
                var playerToolBarItems = self.toolBar.items
                let playButtonIndex = playerToolBarItems?.index(of: self.playBarButtonItem)
                let pauseButtonIndex = playerToolBarItems?.index(of: self.pauseBarButtonItem)
                
                
                if isPlaying {
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
                
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.canChangePlayState
            .drive(playBarButtonItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
    }

    func refreshUI() {
        guard self.isViewLoaded == true else { return }

        viewModel.isPlayerBlocked
            .drive(onNext: { [unowned self] (isBlocked) in
                if isBlocked == true && self.blockOverlayView.superview == nil {
                    
                    self.blockOverlayView.frame = self.view.bounds
                    self.view.addSubview(self.blockOverlayView)
                    
                    NSLayoutConstraint.activate([self.blockOverlayView.topAnchor.constraint(equalTo: self.view.topAnchor),
                                                 self.blockOverlayView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                                 self.blockOverlayView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                                 self.blockOverlayView.rightAnchor.constraint(equalTo: self.view.rightAnchor)])
                    
                } else if isBlocked == false && self.blockOverlayView.superview != nil {
                    
                    self.blockOverlayView.removeFromSuperview()
                }
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.playerItemNameString
            .drive(playerItemNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.playerItemArtistNameString
            .drive(playerItemArtistNameLabel.rx.text)
            .disposed(by: rx.disposeBag)

        viewModel.separatorHidden
            .drive(playerItemNameSeparatorLabel.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        viewModel.playerItemDurationString
            .drive(playerItemDurationLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.canForward
            .drive(forwardBarButtonItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canBackward
            .drive(backwardBarButtonItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        let playerItemTrackLikeState = self.viewModel.playerItemTrackLikeState
        
        playerItemTrackLikeState.map { $0.isLiked ? #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 1) : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1) }
            .drive(onNext: { [unowned self] (x) in
                self.likeBarButtonItem.tintColor = x
            })
            .disposed(by: rx.disposeBag)
        
        playerItemTrackLikeState.map { $0.isDisliked ? #colorLiteral(red: 1, green: 0.3632884026, blue: 0.7128098607, alpha: 1) : #colorLiteral(red: 0.7469480634, green: 0.7825777531, blue: 1, alpha: 1) }
            .drive(onNext: { [unowned self] (x) in
                self.dislikeBarButtonItem.tintColor = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.canChangePlayerItemTrackLikeState
            .drive(likeBarButtonItem.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canSetPlayerItemProgress
            .drive(playerItemProgressView.rx.isUserInteractionEnabled)
            .disposed(by: rx.disposeBag)

        viewModel.isArtistFollowed
            .drive(onNext: { [weak self] (isSelected) in
                self?.regularFollowButton.isSelected = isSelected
                
                self?.compactFollowButton.isSelected = isSelected
                self?.compactFollowButton.tintColor = self?.regularFollowButton.tintColor
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.canFollowArtist
            .drive(regularFollowButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canFollowArtist
            .drive(compactFollowButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canNavigate
            .drive(lyricsButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canNavigate
            .drive(videoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canNavigate
            .drive(promoButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        self.playlistButton.isEnabled = true
        
//        viewModel.previewOptionImage
//            .drive(playerItemPreviewOptionButton.rx.image(for: .normal))
//            .disposed(by: rx.disposeBag)

        viewModel.karaokeEnabled
            .drive(playerItemProgressView.rx.isSelected)
            .disposed(by: rx.disposeBag)
        
        viewModel.karaokeIntervalsViewModel
            .drive(onNext: { [unowned self] (vm) in
                self.playerItemProgressView.update(with: vm)
            })
            .disposed(by: rx.disposeBag)
        
        self.refreshProgressUI()
        
    }

    func refreshProgressUI() {

        viewModel.playerItemRestrictedValue
            .drive(onNext: { [weak self] x in
                self?.playerItemProgressView.restrictedValue = x
            })
            .disposed(by: rx.disposeBag)

        viewModel.playerItemCurrentTimeString
            .drive(playerItemCurrentTimeLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.playerItemProgressValue
            .drive(onNext: { [unowned self] (x) in
                if self.playerItemProgressView.isTracking == false {
                    self.playerItemProgressView.setValue(x, animated: true)
                }
            })
            .disposed(by: rx.disposeBag)

        self.updatePlayPauseState()
    }

}
