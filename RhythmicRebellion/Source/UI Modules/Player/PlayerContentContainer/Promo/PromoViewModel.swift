//
//  PromoViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PromoViewModel: class {

    func load(with delegate: PromoViewModelDelegate)

}

protocol PromoViewModelDelegate: class {

    func refreshUI()

}
