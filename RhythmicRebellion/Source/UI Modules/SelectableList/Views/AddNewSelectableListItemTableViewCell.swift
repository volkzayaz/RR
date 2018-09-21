//
//  AddNewSelectableListItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/20/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol AddNewSelectableListItemTableViewCellViewModel {

    var name: String { get }
}

class AddNewSelectableListItemTableViewCell: UITableViewCell, CellIdentifiable {

    static let identifier = "AddNewSelectableListItemTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var addImageView: UIImageView!

    var viewModelId: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        addImageView.image = addImageView.image?.withRenderingMode(.alwaysTemplate)
    }

    func setup(viewModel: AddNewSelectableListItemTableViewCellViewModel) {

        self.itemNameLabel.text = viewModel.name

    }
}
