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
}

class PlaylistTableHeaderView: UIView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    var viewModelId: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        self.imageView.layer.cornerRadius = 6
        self.imageView.layer.masksToBounds = true
    }

    func setup(viewModel: PlaylistTableHeaderViewModel) {

        self.viewModelId = viewModel.id
        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description
        
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
    }
}
