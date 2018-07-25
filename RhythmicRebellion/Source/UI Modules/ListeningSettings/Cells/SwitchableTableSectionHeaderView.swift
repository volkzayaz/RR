//
//  ListeningSettigsTableHeaderView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/24/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol SwitchableTableSectionHeaderViewModel: class {
    var title: String { get }
    var description: String? { get }
    var isOn: Bool { get set }
    var changeCallback: ((Bool) -> (Void))? { get }
}

class SwitchableTableSectionHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "SwitchableTableHeaderViewIdentifier"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var toggle: UISwitch!

    weak var viewModel: SwitchableTableSectionHeaderViewModel?

    func setup(with viewModel: SwitchableTableSectionHeaderViewModel) {
        self.titleLabel.text = viewModel.title
        self.descriptionLabel.text = viewModel.description

        self.toggle.isOn = viewModel.isOn

        self.viewModel = viewModel
    }

    @IBAction func onToggle(sender: UISwitch) {
        self.viewModel?.changeCallback?(sender.isOn)
    }
}
