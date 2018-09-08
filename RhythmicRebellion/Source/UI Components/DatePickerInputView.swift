//
//  DatePickerInputView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import MaterialTextField

class DateTextField: MFTextField {

    var dateFormatter = DateFormatter()

    var date: Date? {
        didSet {
            guard let date = self.date else { self.text = ""; return }
            self.text = self.dateFormatter.string(from: date)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
    }

}

class DatePickerInputView: UIView {

    @IBOutlet weak var datePicker: UIDatePicker!

    weak var dateTextField: DateTextField?

    override func awakeFromNib() {
        super.awakeFromNib()

        self.datePicker.setValue(UIColor.white, forKey: DatePickerProperties.TextColor.rawValue)
    }

    func bind(with dateTextField: DateTextField) {
        self.dateTextField = dateTextField
        self.dateTextField?.inputView = self

        if let date = self.dateTextField?.date {
            self.datePicker.date = date
        }
    }

    private enum DatePickerProperties: String {
        case TextColor = "textColor"
    }

    // MARK: - ACTIONS -
    @IBAction func onDone(sender: Any) {
        guard let dateTextField = self.dateTextField else { return }

        dateTextField.date = self.datePicker.date
        if dateTextField.delegate?.textFieldShouldReturn?(dateTextField) == true {
            self.dateTextField?.resignFirstResponder()
        }
    }
}
