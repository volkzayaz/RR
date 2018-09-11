//
//  ProfileViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ProfileViewModel: class {

    var userName: String { get }

    func load(with delegate: ProfileViewModelDelegate)

    func numberOfItems(in section: Int) -> Int
    func object(at indexPath: IndexPath) -> ProfileItemViewModel?
    func selectObject(at indexPath: IndexPath)

    func logout()
}

protocol ProfileViewModelDelegate: class {

    func refreshUI()
    func reloadUI()

}
