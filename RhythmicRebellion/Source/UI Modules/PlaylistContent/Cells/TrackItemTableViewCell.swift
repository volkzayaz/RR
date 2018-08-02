//
//  TrackItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol TrackItemTableViewCellViewModel {

    var id: String { get }

    var title: String { get }
    var description: String { get }

}

class TrackItemTableViewCell: UITableViewCell, CellIdentifiable {

    static let identifier = "TrackItemTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    var viewModelId: String = ""

    func settup(viewModel: TrackItemTableViewCellViewModel) {

        self.viewModelId = viewModel.id

        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description
    }

}
