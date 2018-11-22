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

    private(set) var viewModel: PromoViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PromoViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true

        self.infoTextView.textContainer.lineFragmentPadding = 0
        self.infoTextView.textContainerInset = .zero

        viewModel.load(with: self)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

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
        self.viewModel.navigateToAuthorization()
    }

    @IBAction func onToggleSilenceBIOandCommentary(sender: UISwitch) {
        self.viewModel.setSkipAddons(skip: sender.isOn)
    }
}

// MARK: - Router -
extension PromoViewController {

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

extension PromoViewController: PromoViewModelDelegate {

    func reloadThumbnailImage() {
        if let thumbnailURL = viewModel.thumbnailURL() {
            self.imageView.image = nil
            self.activityIndicatorView.startAnimating()
            self.imageView.af_setImage(withURL: thumbnailURL,
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

    func refreshUI() {
        self.reloadThumbnailImage()

        self.artistNameLabel.text = self.viewModel.artistName
        self.trackNameLabel.text = self.viewModel.trackName

        self.silenceBIOandCommentarySwitch.isOn = self.viewModel.isAddonsSkipped

        self.infoTextView.text = self.viewModel.infoText
        self.writerNameLabel.text = self.viewModel.writerName

        self.artistSiteButton.isEnabled = self.viewModel.canVisitArtistSite
        self.writerSiteButton.isEnabled = self.viewModel.canVisitWriterSite

        self.silenceBIOandCommentarySwitch.isEnabled = self.viewModel.canToggleSkipAddons
        self.silenceBIOandCommentarySwitchTapGestureRecognizer.isEnabled = self.silenceBIOandCommentarySwitch.isEnabled == false
    }

}
