//
//  MyPlaylistsViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

import RxDataSources

final class MyPlaylistsViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy var dataSource = RxCollectionViewSectionedAnimatedDataSource<AnimatableSectionModel<String, TrackGroupViewModel<FanPlaylist>>>(configureCell: { [unowned self] (_, collectionView, ip, data) in
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.albumCell,
                                                      for: ip)!
        
        cell.viewModel = data
        
        return cell
        
    }, configureSupplementaryView: { [unowned self] (_, collectionView, kind, ip) in
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                   withReuseIdentifier: R.reuseIdentifier.myPlaylistHeader.identifier,
                                                                   for: ip) as! MyPlaylistsHeaderView
    
        view.viewModel = self.viewModel
        
        view.searchBar.delegate = self
        
        return view
    })
    
    var viewModel: MyPlaylistsViewModel!
    

    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (collectionView.collectionViewLayout as? BaseFlowLayout)?
            .configureFor(bounds: view.bounds)
        
        collectionView.register(R.nib.albumCell)
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        viewModel.dataSource
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: rx.disposeBag)
        
        collectionView.rx.modelSelected(TrackGroupViewModel<FanPlaylist>.self)
            .subscribe(onNext: { [weak self] x in
                self?.viewModel.select(viewModel: x)
            })
            .disposed(by: rx.disposeBag)
    }
    
}

extension MyPlaylistsViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.queryChanged(q: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        self.searchBar(searchBar, textDidChange: "")
    }
    
}
