//
//  DefaultPrimaryListeningSettingCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol SwitchableTableViewCellViewModel: class {
    var title: String { get }
    var description: String? { get }
    var isOn: Bool { get set }
    var changeCallback: ((Bool) -> (Void))? { get }
}

class SwitchableTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SwitchableTableViewCellIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var toggle: UISwitch!

    weak var viewModel: SwitchableTableViewCellViewModel?

    func setup(with viewModel: SwitchableTableViewCellViewModel) {
        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description
        self.toggle.isOn = viewModel.isOn

        self.viewModel = viewModel
    }

    @IBAction func onToggle(sender: UISwitch) {
        self.viewModel?.isOn = sender.isOn
        self.viewModel?.changeCallback?(sender.isOn)
    }
}
