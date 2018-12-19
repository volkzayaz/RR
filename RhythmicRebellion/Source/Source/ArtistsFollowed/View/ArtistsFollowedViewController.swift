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
import RxDataSources

class ArtistsFollowedViewController: UIViewController, MVVM_View {
    
    var viewModel: ArtistsFollowedViewModel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var baseLayout: BaseFlowLayout!
    
    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, Artist>>(configureCell: { [unowned self] (_, collectionView, ip, x) in
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.artistCell,
                                                      for: ip)!
        
        cell.nameLabel.text = x.name
        
        return cell
    })
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseLayout.configureFor(bounds: view.bounds)
        
        viewModel.dataSource
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
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
