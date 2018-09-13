//
//  AddToPlaylistViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AddToPlaylistTableViewCellViewModel {
    var identifier : String {get}
    func configure(cell: UITableViewCell)
}


protocol AddToPlaylistViewModel: class {
    func load(with delegate: AddToPlaylistViewModelDelegate)
    
    func numberOfItems() -> Int
    func object(at indexPath: IndexPath) -> AddToPlaylistTableViewCellViewModel?
    func selectObject(at indexPath: IndexPath)
    
    func cancel()
}

protocol AddToPlaylistViewModelDelegate: class, ErrorPresenting, ProgressPresenting {
    func refreshUI()
}
