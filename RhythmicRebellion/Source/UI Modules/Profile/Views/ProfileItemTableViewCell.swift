//
//  ProfileItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol ProfileItemTableViewCellViewModel {

    var id: String { get }
    var title: String { get }
}

class ProfileItemTableViewCell: UITableViewCell, CellIdentifiable {

    static let identifier = "ProfileItemTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var disclosureImageView: UIImageView!

    var viewModelId: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()

        self.disclosureImageView.image = self.disclosureImageView.image?.withRenderingMode(.alwaysTemplate)
    }

    func setup(viewModel: ProfileItemTableViewCellViewModel) {

        self.viewModelId = viewModel.id
        self.titleLabel.text = viewModel.title
    }
}
