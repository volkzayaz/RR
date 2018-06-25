//
//  AppViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AppViewModel: class {

    func load(with delegate: AppViewModelDelegate)

    func togglePlayerDisclosure()
}

protocol AppViewModelDelegate: class {

    func refreshUI()
    func playerDisclosureStateChanged(isDisclosed: Bool)

}
