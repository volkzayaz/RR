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

class ArtistsFollowedViewController: UITableViewController, MVVM_View {
    
    var viewModel: ArtistsFollowedViewModel!
    
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.backgroundImage = UIImage()
        }
    }

    lazy var rxDataSource = RxTableViewSectionedAnimatedDataSource<AnimatableSectionModel<String, Artist>>(configureCell: { [unowned self] (_, tv: UITableView, ip, x) in
        
        let cell = tv.dequeueReusableCell(withIdentifier: R.reuseIdentifier.artistFollowedCell,
                                          for: ip)!
        
        cell.artist = x
        cell.unfollow = { [weak self] in
            self?.viewModel.unfollow(artist: x)
        }
        
        return cell
    })
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        
        view.backgroundColor = UIColor(red: 0.04,
                                       green: 0.07,
                                       blue: 0.23, alpha: 1)
        
        viewModel.dataSource
            .drive(tableView.rx.items(dataSource: rxDataSource))
            .disposed(by: rx.disposeBag)
        
        tableView.rx.modelSelected(Artist.self)
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
