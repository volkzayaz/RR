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
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resignFirstResponder()
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
        if (motion == .motionShake)
        {
            UIAlertView(title: "Info", message: "Current Environent: \(SettingsStore.environment.value)"
                , delegate: nil, cancelButtonTitle: "Ok").show()
        }
        
    }
    
}

extension RootViewController {
    
    @IBAction func presentVideo(_ sender: Any) {
        viewModel.presentVideo()
    }
    
    @IBAction func presentLyrics(_ sender: Any) {
        viewModel.presentLyrics()
    }
    
    @IBAction func presentPromo(_ sender: Any) {
        viewModel.presentPromo()
    }
    
    @IBAction func presentPlaying(_ sender: Any) {
        viewModel.presentPlaying()
    }
    
    @IBAction func presentPlayer(_ sender: Any) {
        viewModel.presentPlayer()
    }
       
}
