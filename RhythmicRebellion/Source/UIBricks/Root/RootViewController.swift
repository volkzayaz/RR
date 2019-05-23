//
//  RootViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/23/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class RootViewController: UIViewController, MVVM_View {
    
    var viewModel: RootViewModel!
    
    /**
     *  Connect any IBOutlets here
     *  @IBOutlet weak var label: UILabel!
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /**
         *  Set up any bindings here
         *  viewModel.labelText
         *     .drive(label.rx.text)
         *     .addDisposableTo(rx_disposeBag)
         */
        
    }
    
}

extension RootViewController {
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
