//
//  PromoViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import AlamofireImage

final class PromoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var trackNameLabel: UILabel!

    @IBOutlet weak var artistSiteButton: UIButton!

    @IBOutlet weak var silenceBIOandCommentarySwitch: UISwitch!
    @IBOutlet weak var silenceBIOandCommentarySwitchTapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var infoTextView: UITextView!

    @IBOutlet weak var writerNameLabel: UILabel!
    @IBOutlet weak var writerSiteButton: UIButton!


    // MARK: - Public properties -

    var viewModel: PromoViewModel!

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true

        self.infoTextView.textContainer.lineFragmentPadding = 0
        self.infoTextView.textContainerInset = .zero

        self.refreshUI()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        guard self.isViewLoaded else { return }

        coordinator.animate(alongsideTransition: { (transitionCoordinatorContext) in

        }) { (transitionCoordinatorContext) in
            self.reloadThumbnailImage()
        }
    }


    // MARK: - Actions -
    @IBAction func onArtistSite(sender: Any?) {
        self.viewModel.visitArtistSite()
    }

    @IBAction func onWriterSite(sender: Any?) {
        self.viewModel.visitWriterSite()
    }

    @IBAction func handleSilenceBIOandCommentarySwitchTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        self.viewModel.routeToAuthorization()
    }

    @IBAction func onToggleSilenceBIOandCommentary(sender: UISwitch) {
        self.viewModel.setSkipAddons(skip: sender.isOn)
    }
}

extension PromoViewController: PromoViewModelDelegate {

    func reloadThumbnailImage() {
        if let thumbnailURL = viewModel.thumbnailURL() {
            self.imageView.image = nil
            self.activityIndicatorView.startAnimating()
            self.imageView.af_setImage(withURL: thumbnailURL,
                                       placeholderImage: UIImage(named: "TrackImagePlaceholder"),
                                       filter: AspectScaledToFillSizeFilter(size: self.imageView.bounds.size)) { [weak self] (thumbnailImageResponse) in

                                        switch thumbnailImageResponse.result {
                                        case .success(let thumbnailImage):
                                            self?.imageView.image = thumbnailImage

                                        default: break
                                        }

                                        self?.activityIndicatorView.stopAnimating()
            }
        } else {
//            self.imageView.makePlaylistPlaceholder()
            self.activityIndicatorView.stopAnimating()
        }
    }

    func refreshSkipAddonsUI() {
        
        viewModel.isAddonsSkipped
            .drive(silenceBIOandCommentarySwitch.rx.isOn)
            .disposed(by: rx.disposeBag)
        
        viewModel.canToggleSkipAddons
            .drive(silenceBIOandCommentarySwitch.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canToggleSkipAddons
            .map { !$0 }
            .drive(onNext: { [unowned self] (x) in
                self.silenceBIOandCommentarySwitchTapGestureRecognizer.isEnabled = x
            })
            .disposed(by: rx.disposeBag)
        
    }

    func refreshUI() {
        self.reloadThumbnailImage()

        viewModel.artistName
            .drive(artistNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.trackName
            .drive(trackNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.infoText
            .drive(infoTextView.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.writerName
            .drive(writerNameLabel.rx.text)
            .disposed(by: rx.disposeBag)
        
        viewModel.canVisitArtistSite
            .drive(artistSiteButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        viewModel.canVisitWriterSite
            .drive(writerSiteButton.rx.isEnabled)
            .disposed(by: rx.disposeBag)
        
        self.refreshSkipAddonsUI()
    }

}
