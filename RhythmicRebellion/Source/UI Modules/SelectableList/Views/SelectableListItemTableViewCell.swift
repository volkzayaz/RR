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
    
    var title: String { get }
    var isSelected: Bool { get }
}

class SelectableListItemTableViewCell: UITableViewCell, CellIdentifiable {

    typealias ActionCallback = (Actions) -> Void

    enum Actions {
        case select
    }

    static let identifier = "SelectableListItemTableViewCellIdentifier"

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectIndicatorImageView: UIImageView!

    var viewModelId: String = ""

    var actionCallback: ActionCallback?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.containerView.layer.cornerRadius = 15.0
        self.containerView.layer.masksToBounds = true

        selectIndicatorImageView.image = selectIndicatorImageView.image?.withRenderingMode(.alwaysTemplate)
    }

    func setup(viewModel: SelectableListItemTableViewCellViewModel, actionCallback:  @escaping ActionCallback) {

        self.viewModelId = viewModel.id
        self.titleLabel.text = viewModel.title
        self.selectIndicatorImageView.isHidden = viewModel.isSelected == false

        self.actionCallback = actionCallback
    }

    @IBAction func onSelect(sender: Any?) {
        actionCallback?(.select)
    }
}
