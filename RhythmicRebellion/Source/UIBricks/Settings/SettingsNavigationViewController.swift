//
//  SettingsNavigationViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/5/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class SettingsNavigationViewController: UINavigationController, MVVM_View {
    
    lazy var viewModel: SettingsNavigationViewModel! = SettingsNavigationViewModel(router: .init(owner: self))
    
    /**
     *  Connect any IBOutlets here
     *  @IBOutlet weak var label: UILabel!
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = viewModel
    }
    
}

extension SettingsNavigationViewController {
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
