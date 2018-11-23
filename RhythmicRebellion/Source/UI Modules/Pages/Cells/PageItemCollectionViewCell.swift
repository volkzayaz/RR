//
//  PageItemCollectionViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol PageItemCollectionViewCellViewModel {

    var id: Int { get }
    var image: UIImage? { get }
}

class PageItemImageContainerView: UIView {

    @IBOutlet weak var imageView: UIImageView!
}

class PageItemCollectionViewCell: UICollectionViewCell, CellIdentifiable {

    static let identifier = "PageItemCollectionViewCellIdentifier"

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case delete
    }

    @IBOutlet weak var containerView: PageItemImageContainerView!

//    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var gradientView: UIView!

    var viewModelId: Int = -1

    var actionCallback: ActionCallback?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.layer.masksToBounds = true
        self.containerView.layer.cornerRadius = 0
    }

    func setup(viewModel: PageItemCollectionViewCellViewModel, actionCallback:  @escaping ActionCallback) {

        self.viewModelId = viewModel.id
        self.containerView.imageView.image = viewModel.image

        self.actionCallback = actionCallback
    }

    // MARK: - Actions -

    @IBAction func onDelete(sender: Any?) {
        self.actionCallback?(.delete)
    }
}

extension PageItemImageContainerView: ZoomAnimatorSourceImageContainerView {
    var image: UIImage? { return imageView.image }
    var imageContentMode: ContentMode { return imageView.contentMode }
}
