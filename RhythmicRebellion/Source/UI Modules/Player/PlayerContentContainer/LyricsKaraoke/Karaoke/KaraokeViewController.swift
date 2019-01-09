//
//  KaraokeViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import AlamofireImage


final class KaraokeViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var headerView: KaraokeHeaderView!
    @IBOutlet weak var headerViewTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerView: KaraokeFooterView!
    @IBOutlet weak var footerViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerViewHeightLayoutConstraint: NSLayoutConstraint!


    // MARK: - Public properties -

    private(set) var viewModel: KaraokeViewModelProtocol!
    private(set) var router: FlowRouter!

    private weak var hideControlsTimer: Timer?

    // MARK: - Configuration -

    func configure(viewModel: KaraokeViewModelProtocol, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.footerView.scrollViewModeButton.setBorderWidth(1.0, for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.scrollViewModeButton.setBorderWidth(1.0, for: UIControl.State.selected)

        self.footerView.scrollViewModeButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.scrollViewModeButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: UIControl.State.selected)

        self.footerView.onePhraseViewModeButton.setBorderWidth(1.0, for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.onePhraseViewModeButton.setBorderWidth(1.0, for: UIControl.State.selected)

        self.footerView.onePhraseViewModeButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.onePhraseViewModeButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: UIControl.State.selected)

        self.footerView.vocaltrackButton.setBorderWidth(1.0, for: [UIControl.State.normal, UIControl.State.highlighted])
        self.footerView.vocaltrackButton.setBorderWidth(1.0, for: UIControl.State.normal)
        self.footerView.vocaltrackButton.setBorderWidth(1.0, for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.vocaltrackButton.setBorderWidth(1.0, for: UIControl.State.selected)

        self.footerView.vocaltrackButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.vocaltrackButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: UIControl.State.selected)
        self.footerView.vocaltrackButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: [UIControl.State.normal, UIControl.State.highlighted])
        self.footerView.vocaltrackButton.setBorderColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: UIControl.State.normal)

        self.footerView.vocaltrackButton.setBackgroundColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: [UIControl.State.selected, UIControl.State.highlighted])
        self.footerView.vocaltrackButton.setBackgroundColor(#colorLiteral(red: 0.7294117647, green: 0.768627451, blue: 0.9803921569, alpha: 1), for: UIControl.State.selected)

        viewModel.load(with: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.headerViewTopLayoutConstraint.constant = 0.0
        self.footerViewBottomLayoutConstraint.constant = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.scheduleHideControlsTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var contentInset = self.collectionView.contentInset
        contentInset.top = self.view.bounds.height / 2
        contentInset.bottom = self.view.bounds.height / 2
        self.collectionView.contentInset = contentInset
        self.collectionView.collectionViewLayout.invalidateLayout()

        if let currentItemIndexPath = self.viewModel.currentItemIndexPath {
            self.collectionView.scrollToItem(at: currentItemIndexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] (context) in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] (context) in
            self?.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.collectionView.collectionViewLayout.invalidateLayout()
    }


    // MARK: - Timer -

    func scheduleHideControlsTimer() {

        self.hideControlsTimer?.invalidate()

        self.hideControlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { [weak self] (timer) in
            guard let self = self else { return }

            self.hideControlsTimer = nil

            self.headerViewTopLayoutConstraint.constant = -self.headerViewHeightLayoutConstraint.constant
            self.footerViewBottomLayoutConstraint.constant = -self.footerViewHeightLayoutConstraint.constant

            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
                self?.contentView.layoutIfNeeded()
                }, completion: { (success) in
            })
        })
    }

    // MARK: - Actions -

    @IBAction func onTap() {

        guard self.hideControlsTimer == nil else {
            self.scheduleHideControlsTimer()
            return
        }

        self.headerViewTopLayoutConstraint.constant = 0.0
        self.footerViewBottomLayoutConstraint.constant = 0.0

        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] in
            self?.contentView.layoutIfNeeded()
        }) { [weak self] (success) in
            self?.scheduleHideControlsTimer()
        }
    }

    @IBAction func onClose() {
        self.viewModel.switchToLyrics()
    }

    @IBAction func onScrollViewMode() {
        self.viewModel.change(viewMode: .scroll)
    }

    @IBAction func onOnePhraseViewMode() {
        self.viewModel.change(viewMode: .onePhrase)
    }

    @IBAction func onVocalTrack() {
        self.viewModel.changeAudioFileType()
    }
}


extension KaraokeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, KaraokeCollectionViewFlowLayoutViewModel {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.numberOfItems(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let karaokeIntervalCollectionViewCell = KaraokeIntervalCollectionViewCell.reusableCell(in: collectionView, at: indexPath)
        let karaokeIntervalCellViewModel = self.viewModel.item(at: indexPath)!

        karaokeIntervalCollectionViewCell.setup(viewModel: karaokeIntervalCellViewModel)

        return karaokeIntervalCollectionViewCell

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let karaokeCollectionViewFlowLayout = collectionViewLayout as? KaraokeCollectionViewFlowLayout else {
            fatalError("Incorrect KaraokeCollectionViewLayout")
        }

        return karaokeCollectionViewFlowLayout.itemSize(at: indexPath, with: self)
    }

    func itemSize(at indexPath: IndexPath, for width: CGFloat) -> CGSize {
        return self.viewModel.itemSize(at: indexPath, for: width)
    }
}

// MARK: - Router -
extension KaraokeViewController {

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

extension KaraokeViewController: KaraokeViewModelDelegate {

    func reloadUI() {

        if let thumbnailURL = viewModel.thumbnailURL() {
            self.imageView.image = nil
            self.imageView.af_setImage(withURL: thumbnailURL,
                                       placeholderImage: UIImage(named: "TrackImagePlaceholder")) { [weak self] (thumbnailImageResponse) in

                                        switch thumbnailImageResponse.result {
                                        case .success(let thumbnailImage):
                                            self?.imageView.image = thumbnailImage

                                        default: break
                                        }
            }
        }

        self.collectionView.reloadData()

        self.refreshUI()
    }


    func refreshViewModeUI() {

        switch self.viewModel.viewMode {
        case .scroll:

            self.footerView.scrollViewModeButton.isSelected = true
            self.footerView.onePhraseViewModeButton.isSelected = false

            guard (self.collectionView.collectionViewLayout as? KaraokeScrollCollectionViewFlowLayout) == nil else { return }

            let karaokeScrollCollectionViewFlowLayout = KaraokeScrollCollectionViewFlowLayout()
            karaokeScrollCollectionViewFlowLayout.minimumLineSpacing = 10.0
            karaokeScrollCollectionViewFlowLayout.minimumInteritemSpacing = 0.0


            self.collectionView.setCollectionViewLayout(karaokeScrollCollectionViewFlowLayout, animated: false)
            self.collectionView.reloadData()

            if let currentItemIndexPath = self.viewModel.currentItemIndexPath {
                self.collectionView.scrollToItem(at: currentItemIndexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
            }


        case .onePhrase:

            self.footerView.scrollViewModeButton.isSelected = false
            self.footerView.onePhraseViewModeButton.isSelected = true

            guard (self.collectionView.collectionViewLayout as? KaraokeOnePhraseCollectionViewFlowLayout) == nil else { return }

            let karaokeOnePhraseCollectionViewFlowLayout = KaraokeOnePhraseCollectionViewFlowLayout()

            self.collectionView.setCollectionViewLayout(karaokeOnePhraseCollectionViewFlowLayout, animated: false)
            self.collectionView.reloadData()
            if let currentItemIndexPath = self.viewModel.currentItemIndexPath {
                self.collectionView.scrollToItem(at: currentItemIndexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: false)
            }
        }
    }

    func refreshUI() {

        self.refreshViewModeUI()

        self.footerView.vocaltrackButton.isSelected = self.viewModel.isVocalAudioFile
        self.footerView.vocaltrackButton.isEnabled = self.viewModel.canChangeAudioFileType

        if let currentItemIndexPath = self.viewModel.currentItemIndexPath {
            self.collectionView.scrollToItem(at: currentItemIndexPath, at: UICollectionView.ScrollPosition.centeredVertically, animated: true)
        } else {
            self.collectionView.setContentOffset(CGPoint(x: 0.0, y: -self.collectionView.contentInset.top), animated: true)
        }
    }
}
