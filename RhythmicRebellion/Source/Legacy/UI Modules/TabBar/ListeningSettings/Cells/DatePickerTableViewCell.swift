//
//  DatePickerTableViewCell.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/24/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol DatePickerTableVieCellViewModel: class {
    var date: Date { get set}
    var changeCallback: ((Date) -> (Void))? { get }
}


class DatePickerTableVieCell: UITableViewCell {

    static let reuseIdentifier = "DatePickerTableVieCellIdentifier"

    private enum DatePickerProperties: String {
        case TextColor = "textColor"
    }

    @IBOutlet weak var datePicker: UIDatePicker!

    weak var viewModel: DatePickerTableVieCellViewModel?

    public override func awakeFromNib() {
        super.awakeFromNib()

        self.datePicker.setValue(UIColor.white, forKey: DatePickerProperties.TextColor.rawValue)
    }

    func setup(with viewModel: DatePickerTableVieCellViewModel) {

        datePicker.setDate(viewModel.date, animated: false)

        self.viewModel = viewModel
    }

    @IBAction func onDatePickerChanged(sender: UIDatePicker) {

        self.viewModel?.date = sender.date
        self.viewModel?.changeCallback?(sender.date)
    }
}
