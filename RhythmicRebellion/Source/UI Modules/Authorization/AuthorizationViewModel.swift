//
//  AuthorizationViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol AuthorizationViewModel: class {

    func load(with delegate: AuthorizationViewModelDelegate)

    func change(authorizationType: AuthorizationType)
}

protocol AuthorizationViewModelDelegate: class {

    func refreshUI()

}
