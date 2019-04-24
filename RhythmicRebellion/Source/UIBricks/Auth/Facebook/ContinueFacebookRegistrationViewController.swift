//
//  ContinueFacebookRegistrationViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 4/14/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

import SwiftValidator

class ContinueFacebookRegistrationViewController: UIViewController, MVVM_View {
    
    var viewModel: ContinueFacebookRegistrationViewModel!
    
    @IBOutlet weak var birthdayField: DateTextField!
    @IBOutlet weak var birthdayErrorLabel: UILabel!
    @IBOutlet var birthdayPickerView: DatePickerInputView!
    
    @IBOutlet weak var selectCountryField: CountryTextField!
    @IBOutlet weak var errorCountryLabel: UILabel!
    
    @IBOutlet weak var termsAndConditionsCheckmark: Checkbox!
    @IBOutlet weak var dataStoredCheckmark: Checkbox!
    @IBOutlet weak var dataStoredLabel: UILabel!
    @IBOutlet weak var advertisersCheckmark: Checkbox!
    @IBOutlet weak var advertisersLabel: UILabel!
    
    let validator = Validator()
    
    /**
     *  Connect any IBOutlets here
     *  @IBOutlet weak var label: UILabel!
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        [termsAndConditionsCheckmark, dataStoredCheckmark, advertisersCheckmark].forEach { x in
            x?.borderStyle = .square
            
            x?.layer.cornerRadius = 3
            
            x?.checkmarkStyle = .tick
            x?.useHapticFeedback = true
            
            x?.checkedBackgroundColor = UIColor(fromHex: 0xFF3EA7)
            x?.checkboxBackgroundColor = .init(fromHex: 0x0B133A)
            
            x?.uncheckedBorderColor = .init(fromHex: 0xB1B9FF)
            x?.checkedBorderColor = .init(fromHex: 0x0B133A)
            
            x?.checkmarkColor = .init(fromHex: 0x0B133A)
            
            x?.increasedTouchRadius = 5
        }
        
        validator.registerField(birthdayField, errorLabel: birthdayErrorLabel, rules: [RequiredRule()])
        validator.registerField(selectCountryField, errorLabel: errorCountryLabel, rules: [RequiredRule()])
        
        birthdayPickerView.bind(with: birthdayField)
        birthdayField.inputAssistantItem.leadingBarButtonGroups = [];
        birthdayField.inputAssistantItem.trailingBarButtonGroups = [];
     
        viewModel.country
            .subscribe(onNext: { [unowned self] (x) in
                self.selectCountryField.country = x
            })
            .disposed(by: rx.disposeBag)
        
        viewModel.extraTicksHidden
            .drive(onNext: { [unowned self] (hidden) in
                
                self.dataStoredCheckmark.isChecked = hidden
                self.dataStoredCheckmark.isHidden = hidden
                self.dataStoredLabel.isHidden = hidden
                
                self.advertisersCheckmark.isChecked = hidden
                self.advertisersCheckmark.isHidden = hidden
                self.advertisersLabel.isHidden = hidden
                
            })
            .disposed(by: rx.disposeBag)
        
    }
    
    @IBAction func createAction(_ sender: Any) {
        
        guard termsAndConditionsCheckmark.isChecked,
            dataStoredCheckmark.isChecked,
            advertisersCheckmark.isChecked else {
                return presentErrorMessage(error: "You should tick all checkmarks before completing registration")
            }
        
        var res = false
        validator.validate { (error) in
            res = error.count == 0
            
            [birthdayErrorLabel, errorCountryLabel].forEach { $0?.isHidden = true }
            
            error.forEach { x in
                x.1.errorLabel?.isHidden = false
                x.1.errorLabel?.text = x.1.errorMessage
            }
        }
        
        guard res else { return }
        
        viewModel.createAccount(birthday: birthdayField.date!,
                                country: selectCountryField.country!)
    }
    
}

extension ContinueFacebookRegistrationViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == selectCountryField {
            viewModel.presentCountrySelection()
            return false
        }
        
        return true
    }
    
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
