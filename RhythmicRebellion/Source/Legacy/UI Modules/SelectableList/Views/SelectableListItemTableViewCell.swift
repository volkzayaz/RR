//
//  SelectableListItemTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/31/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol SelectableListItemTableViewCellViewModel {

    var id: String { get }
    
    var name: String { get }
    var isSelected: Bool { get }
}

class SelectableListItemTableViewCell: UITableViewCell, CellIdentifiable {

    static let identifier = "SelectableListItemTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectIndicatorImageView: UIImageView!

    var viewModelId: String = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        selectIndicatorImageView.image = selectIndicatorImageView.image?.withRenderingMode(.alwaysTemplate)
    }

    func setup(viewModel: SelectableListItemTableViewCellViewModel) {

        self.viewModelId = viewModel.id
        self.titleLabel.text = viewModel.name
        self.selectIndicatorImageView.isHidden = viewModel.isSelected == false

    }
}
