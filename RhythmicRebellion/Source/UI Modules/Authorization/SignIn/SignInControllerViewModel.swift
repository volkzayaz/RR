//
//  SignInControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

struct SignInUserCredentials: UserCredentials {
    let email: String
    let password: String
}

final class SignInControllerViewModel: SignInViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: SignInViewModelDelegate?
    private(set) weak var router: SignInRouter?
    private(set) weak var application: Application?

    // MARK: - Lifecycle -

    init(router: SignInRouter, application: Application) {
        self.router = router
        self.application = application
    }

    func load(with delegate: SignInViewModelDelegate) {
        self.delegate = delegate
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {

        let signInUserCredentials = SignInUserCredentials(email: email, password: password)

        self.application?.signIn(with: signInUserCredentials, completion: completion)
    }
}
