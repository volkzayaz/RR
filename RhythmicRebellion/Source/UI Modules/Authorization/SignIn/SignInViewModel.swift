//
//  SignInViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol SignInViewModel: class {

    func load(with delegate: SignInViewModelDelegate)

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void)
}

protocol SignInViewModelDelegate: class {

    func refreshUI()

}
