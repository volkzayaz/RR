//
//  PlaylistTableViewHeader.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import AlamofireImage

protocol PlaylistTableHeaderViewModel {

    var id: String { get }

    var title: String? { get }
    var description: String? { get }

    var thumbnailURL: URL? { get }

    var canClear: Bool { get }
}

class PlaylistTableHeaderView: UIView {

    typealias ActionCallback = (Actions) -> Void
    
    enum Actions {
        case showActions
        case clear
    }

    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var actionButton: UIButton!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var clearPlaylistButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var clearPlaylistButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var clearPlaylistButtonBottomConstraint: NSLayoutConstraint!

    var viewModelId: String = ""

    var actionCallback: ActionCallback?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true
    }

    func setup(viewModel: PlaylistTableHeaderViewModel, actionCallback:  @escaping ActionCallback) {

        self.viewModelId = viewModel.id
        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        self.clearPlaylistButtonBottomConstraint.constant = viewModel.canClear ? 0 : -(clearPlaylistButtonHeightConstraint.constant + clearPlaylistButtonTopConstraint.constant)

        self.infoView.setNeedsLayout()
        self.infoView.layoutIfNeeded()

        if let thumbnailURL = viewModel.thumbnailURL {
            self.activityIndicatorView.startAnimating()
            self.imageView.af_setImage(withURL: thumbnailURL,
                                       filter: ScaledToSizeFilter(size: CGSize(width: 360, height: 360))) { [weak self, viewModel] (thumbnailImageResponse) in

                                        guard let `self` = self, self.viewModelId == viewModel.id else {
                                            return
                                        }
                                        switch thumbnailImageResponse.result {
                                        case .success(let thumbnailImage):
                                            self.imageView.image = thumbnailImage

                                        default: break
                                        }

                                        self.activityIndicatorView.stopAnimating()
            }
        } else {
            self.imageView.makePlaylistPlaceholder()
            self.activityIndicatorView.stopAnimating()
        }

        self.actionCallback = actionCallback
    }

    func updateFrame(in view: UIView, for traitCollection: UITraitCollection) {

        var frame = self.frame
        if traitCollection.horizontalSizeClass == .compact {
            frame.size.height = view.frame.size.width * 0.85
            if self.clearPlaylistButtonBottomConstraint.constant == 0 {
                frame.size.height += 57.0
            }

        } else if traitCollection.horizontalSizeClass == .regular {
            frame.size.height = max(self.infoView.frame.height + 57.0, 93.0)
        }
        self.frame = frame
    }

    // MARK: - Actions -

    @IBAction func onActionButton(sender: UIButton) {
        self.actionCallback?(.showActions)
    }

    @IBAction func onClearPlaylistButton(sender: UIButton) {
        self.actionCallback?(.clear)
    }
}
