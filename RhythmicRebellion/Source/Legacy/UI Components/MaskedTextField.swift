//
//  MaskedTextField.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/20/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import MaterialTextField
import NSStringMask


class MaskedTextField: MFTextField {

    var stringMask: NSStringMask? {
        didSet {
            if self.stringMask != nil {
                if self.internalDelegate !== super.delegate {
                    self.internalDelegate = super.delegate
                }
                super.delegate = self
            } else {
                if self.internalDelegate !== super.delegate {
                     super.delegate = self.internalDelegate
                }
                self.internalDelegate = nil
            }
        }
    }

    private var internalDelegate: UITextFieldDelegate?

    override var delegate: UITextFieldDelegate? {
        get {
            if self.stringMask != nil {
                return self.internalDelegate
            }

            return super.delegate
        }
        set {
            if self.stringMask != nil {
                self.internalDelegate = newValue
            } else {
                super.delegate = newValue
            }
        }
    }

    override var text: String? {
        set {
            guard let stringMask = self.stringMask, let newText = newValue, newText.count > 0 else { super.text = newValue; return }
            super.text = stringMask.format(newText)
        }
        get {
            return super.text
        }
    }

    var unmaskedText: String? { return self.stringMask != nil ? self.stringMask?.validCharacters(for: self.text) : self.text }
}


extension MaskedTextField: UITextFieldDelegate {

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let value = self.internalDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
        guard value == true else { return false }


        var textFieldText = textField.text as NSString? ?? NSString(string: "")
        textFieldText = textFieldText.replacingCharacters(in: range, with: string) as NSString
        var newRange = NSRange(location: 0, length: 0)
        let cleanTextFieldText = self.stringMask?.validCharacters(for: textFieldText as String) as NSString? ?? ""

        if (cleanTextFieldText.length > 0) {
            textField.text = textFieldText as String
            textFieldText = textField.text as NSString? ?? NSString(string: "")
            newRange = textFieldText.range(of: cleanTextFieldText.substring(from: cleanTextFieldText.length - 1) , options: [.backwards])
            if (newRange.location == NSNotFound) {
                newRange.location = textFieldText.length;
            } else {
                newRange.location += newRange.length;
            }

            newRange.length = 0;
        } else {
            textField.text = cleanTextFieldText as String
        }

        textField.setValue(NSValue(range: newRange), forKey: "selectionRange")
        self.sendActions(for: .editingChanged)

        return false
    }



    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let value = self.internalDelegate?.textFieldShouldBeginEditing?(textField) else {
            return true
        }

        return value
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.internalDelegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let value = self.internalDelegate?.textFieldShouldEndEditing?(textField) else {
            return true
        }

        return value
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.internalDelegate?.textFieldDidEndEditing?(textField)
    }

//    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
//        self.internalDelegate?.textFieldDidEndEditing?(textField, reason: reason)
//    }


    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard let value = self.internalDelegate?.textFieldShouldClear?(textField) else {
            return true
        }

        return value
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let value = self.internalDelegate?.textFieldShouldReturn?(textField) else {
            return true
        }

        return value
    }
}
