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
        
        cell.artist = x
        cell.unfollow = { [weak self] in
            self?.viewModel.unfollow(artist: x)
        }
        
        return cell
    })
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        baseLayout.configureFor(bounds: view.bounds)
        
        viewModel.dataSource
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.modelSelected(Artist.self)
            .subscribe(onNext: { [weak self] artist in
                self?.viewModel.select(artist: artist)
            })
            .disposed(by: rx.disposeBag)
        
    }
    
}

extension ArtistsFollowedViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.queryChanges(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.searchBar(searchBar, textDidChange: "")
    }
    
}
