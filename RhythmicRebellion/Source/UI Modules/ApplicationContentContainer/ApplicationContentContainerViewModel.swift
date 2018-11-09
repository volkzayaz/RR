//
//  ApplicationContentContainerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/7/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol ApplicationContentContainerViewModel: class {

    func load(with delegate: ApplicationContentContainerViewModelDelegate)

}

protocol ApplicationContentContainerViewModelDelegate: class {

    func refreshUI()

}
