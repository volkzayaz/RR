//
//  PlaylistCollectionVIewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import AlamofireImage

protocol PlaylistItemCollectionViewCellViewModel {

    var id: String { get }

    var title: String { get }
    var description: String { get }

    var thumbnailURL: URL? { get }

}

class PlaylistItemCollectionViewCell: UICollectionViewCell, CellIdentifiable {

    static let identifier = "PlaylistItemCollectionViewCellIdentifier"

    @IBOutlet weak var shadowContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var gradientView: UIView!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var viewModelId: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = 6

        self.shadowContainerView.layer.masksToBounds = false
        self.shadowContainerView.layer.cornerRadius = self.containerView.layer.cornerRadius
        self.shadowContainerView.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.shadowContainerView.layer.shadowRadius = 2.0
        self.shadowContainerView.layer.shadowOpacity = 0.5
        self.shadowContainerView.layer.shadowPath = UIBezierPath(roundedRect: self.bounds,
                                                                 cornerRadius: self.containerView.layer.cornerRadius).cgPath

        self.shadowContainerView.layer.shouldRasterize = true
        self.shadowContainerView.layer.rasterizationScale = UIScreen.main.scale
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.shadowContainerView.layer.shadowPath = UIBezierPath(roundedRect: self.bounds,
                                                                 cornerRadius: self.containerView.layer.cornerRadius).cgPath
    }

    func setup(viewModel: PlaylistItemCollectionViewCellViewModel) {

        self.viewModelId = viewModel.id

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        if let thumbnailURL = viewModel.thumbnailURL {
            self.activityIndicatorView.startAnimating()
            self.imageView.af_setImage(withURL: thumbnailURL,
                                       filter: ScaledToSizeFilter(size: imageView.frame.size)) { [weak self, viewModel] (thumbnailImageResponse) in

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
        }

    }
}
