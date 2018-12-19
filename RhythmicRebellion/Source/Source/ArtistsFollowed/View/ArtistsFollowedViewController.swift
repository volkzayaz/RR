//
//  ArtistsFollowedViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class ArtistsFollowedViewController: UIViewController, MVVM_View {
    
    var viewModel: ArtistsFollowedViewModel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var baseLayout: BaseFlowLayout!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseLayout.configureFor(bounds: collectionView.bounds)
        
        /**
         *  Set up any bindings here
         *  viewModel.labelText
         *     .drive(label.rx.text)
         *     .addDisposableTo(rx_disposeBag)
         */
        
    }
    
}

extension ArtistsFollowedViewController {
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
