//
//  KaraokeIntervalCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol KaraokeIntervalCellViewModel {

    var text: String? { get }
    var font: UIFont { get }
}

class KaraokeIntervalTableViewCell: UITableViewCell, CellIdentifiable {

    static let identifier = "KaraokeIntervalTableViewCellIdentifier"

    @IBOutlet weak var intervalTextLabel: UILabel!


    func setup(viewModel: KaraokeIntervalCellViewModel) {

        self.intervalTextLabel.font = viewModel.font
        self.intervalTextLabel.text = viewModel.text
    }
}

class KaraokeIntervalCollectionViewCell: UICollectionViewCell, CellIdentifiable {

    static let identifier = "KaraokeIntervalCollectionViewCellIdentifier"

    @IBOutlet weak var intervalTextLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.intervalTextLabel.layoutMargins = UIEdgeInsets.zero
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)

        guard let karaokeLayoutAttributes = layoutAttributes as? KaraokeCollectionViewLayoutAttributes else { return }
        let boundsCenterOffset = karaokeLayoutAttributes.boundsCenterOffset
        let activeDistance = karaokeLayoutAttributes.activeDistance

        if boundsCenterOffset.y >= 0 {
            guard boundsCenterOffset.y <= activeDistance else {
                self.intervalTextLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
                return
            }
            let fromColor = UIColor(white: 1.0, alpha: 1.0)
            let toColor = UIColor(red: 248.0/255.0, green: 231.0/255.0, blue: 28.0/255.0, alpha: 1.0)
            let percentage = (activeDistance - abs(boundsCenterOffset.y)) / (activeDistance)
            self.intervalTextLabel.textColor = UIColor.gradientColor(from: fromColor, to: toColor, percentage: percentage)
        } else {
            guard abs(boundsCenterOffset.y) <= activeDistance else {
                self.intervalTextLabel.textColor = UIColor(white: 1.0, alpha: 0.3)
                return
            }

            let fromColor = UIColor(red: 248.0/255.0, green: 231.0/255.0, blue: 28.0/255.0, alpha: 1.0)
            let toColor = UIColor(white: 1.0, alpha: 0.3)
            let percentage = abs(boundsCenterOffset.y) / activeDistance
            self.intervalTextLabel.textColor = UIColor.gradientColor(from: fromColor, to: toColor, percentage: percentage)
        }
    }

    func setup(viewModel: KaraokeIntervalCellViewModel) {

        self.intervalTextLabel.font = viewModel.font
        self.intervalTextLabel.text = viewModel.text
    }
}
