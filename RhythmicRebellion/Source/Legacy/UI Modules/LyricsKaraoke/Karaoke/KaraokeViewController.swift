//
//  KaraokeViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxCocoa

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

    private(set) var viewModel: KaraokeViewModel!
    private(set) var router: FlowRouter!

    private weak var hideControlsTimer: Timer?

    // MARK: - Configuration -

    func configure(viewModel: KaraokeViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationController?.automaticallyAdjustsScrollViewInsets = false
//        if #available(iOS 11.0, *) {
//            self.collectionView.contentInsetAdjustmentBehavior = .never
//        } else {
//            // Fallback on earlier versions
//        }
        
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

        viewModel.mode
            .map { $0 == .scroll }
            .drive(onNext: { [unowned self] x in
                self.footerView.scrollViewModeButton.isSelected = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.mode
            .map { $0 == .onePhrase }
            .drive(onNext: { [unowned self] x in
                self.footerView.onePhraseViewModeButton.isSelected = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.data.asDriver()
            .notNil()
            .drive(onNext: { [unowned self] tuple in
                
                guard let x = tuple.change else { return }
                
                let reload    = { self.collectionView.reloadData(); }
                let setLayout = { self.collectionView.collectionViewLayout = tuple.layout }
                let scroll    = { (animated: Bool) in
                    
                    guard let i = tuple.activeIndex else {
                        self.collectionView.contentOffset = .zero
                        return
                    }
                    
                    ////f-ing understand proper collection view layout cycle
                    ////and get rid of dispatching after
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: { [weak self] in
                        let x = IndexPath(row: i, section: 0)
                        
                        ////this if is the result of internal AppState inconsistency.
                        ////AppState is initialised as a result of 4 different Socket Messages
                        ////Before they all finished it is possible for AppState to contain "currentItem"
                        ////That is not represented in LinkedPlaylist.
                        ////TODO: remove this check as soon as this inconsistency is resolved
                        guard let t = self?.collectionView.numberOfItems(inSection: 0), t > i else { return }
                        
                        self?.collectionView.scrollToItem(at: x,
                                                          at: .centeredVertically, animated: animated)
                    })
                    
                }
                
                ///layout changes:
                /// set layout -> reload data -> scroll to item
                
                ///data changes:
                /// reloadData -> scrollToItem
                
                ///index changes:
                /// scroll to item
                
                switch x {
                    
                case .layout:
                    setLayout(); reload(); scroll(false)
                    
                case .data:
                    reload(); scroll(false)
                    
                case .index:
                    scroll(true)
                    
                }
                
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.vocalButtonSelected
            .drive(onNext: { [weak f = footerView] (isSelected) in
                f?.vocaltrackButton.isSelected = isSelected
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.canChangeAudioFileType
            .drive(onNext: { [weak f = footerView] (isEnabled) in
                f?.vocaltrackButton.isEnabled = isEnabled
            })
            .disposed(by: rx.disposeBag)
    
        viewModel.thumbnailURL
            .flatMapLatest { (maybeURL) -> Driver<UIImage?> in
                
                guard let url = maybeURL else { return .just(nil) }
                
                return ImageRetreiver.imageForURLWithoutProgress(url: url)
            }
            .map { $0 ?? UIImage(named: "TrackImagePlaceholder") }
            .drive(imageView.rx.image)
            .disposed(by: rx.disposeBag)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.headerViewTopLayoutConstraint.constant = 0.0
        self.footerViewBottomLayoutConstraint.constant = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.scheduleHideControlsTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

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
        self.viewModel.change(mode: .scroll)
    }

    @IBAction func onOnePhraseViewMode() {
        self.viewModel.change(mode: .onePhrase)
    }

    @IBAction func onVocalTrack() {
        self.viewModel.changeAudioFileType()
    }
}


extension KaraokeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.data.value?.viewModels.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.karaokeIntervalCollectionViewCellIdentifier, for: indexPath)!
        
        if let vm = viewModel.data.value?.viewModels[indexPath.row] {
            cell.setup(viewModel: vm)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        guard let karaokeCollectionViewFlowLayout = collectionViewLayout as? KaraokeLayout else {
            
            return viewModel.data.value!.layout.itemSize(at: indexPath, with: self.viewModel)
            
            //fatalError("Incorrect KaraokeCollectionViewLayout")
        }

        return karaokeCollectionViewFlowLayout.itemSize(at: indexPath, with: self.viewModel!)
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
