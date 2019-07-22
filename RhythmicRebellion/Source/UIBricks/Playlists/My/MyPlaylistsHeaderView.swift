//
//  MyPLaylistsHeaderView.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/22/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class MyPlaylistsHeaderView: UICollectionReusableView {
    
    var viewModel: MyPlaylistsViewModel!
    
    @IBOutlet var searchBar: UISearchBar! {
        didSet {
            searchBar.backgroundImage = UIImage()
        }
    }
    
    @IBAction func addPlaylist(_ sender: Any) {
        viewModel.addPlaylist()
    }
    
}
