//
//  AppControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

final class AppControllerViewModel: AppViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AppViewModelDelegate?
    private(set) weak var router: AppRouter?

    private(set) weak var restApiService: RestApiService?
    private(set) weak var webSocketService: WebSocketService?

    var isPlayerDisclosed: Bool = false

    var user: User?

    // MARK: - Lifecycle -

    init(router: AppRouter, restApiService: RestApiService, webSocketService: WebSocketService) {
        self.router = router
        self.restApiService = restApiService
        self.webSocketService = webSocketService
    }

    func load(with delegate: AppViewModelDelegate) {
        self.delegate = delegate

        #if DEBUG
            let email = "alexander@olearis.com"
            let password = "ngrx2Fan"
        #else
            let email = "alena@olearis.com"
            let password = "Olearistest1"
        #endif

        self.restApiService?.fanLogin(email: email, password: password, completion: { (user) in
            self.user = user
            if let user = user {
                self.webSocketService?.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
            }
        })

//        self.restApiService?.getFanUser(completion: { [unowned self] (user) in
//            self.user = user
//            if let user = user {
//
//                let webSocketToken = "32707f7e47c587a369fbbe3ed123beaa512438a068042c7f3a3f06a0bd1f937c"
//                //    private let webSocketToken = "f8b5cb700eb684b075d03867019359a0581fe459b4b33673441a2917464929dc"  //Alena
//
//                //    private let webSocketToken = "f4dd23e815bb3ece8da32f4b4d4f9dc8d12776ae47a7ce0871db086a49b82744"
//                //    private let webSocketToken = "f3b77ecd0889aecfdddf31dd7d108a28db4e3303400413bef9a93175f0eddb1b"
//
//                self.webSocketService?.connect(with: Token(token: webSocketToken, isGuest: self.user?.isGuest ?? true))
//            }
//        })
    }

    func togglePlayerDisclosure() {
        self.isPlayerDisclosed = !self.isPlayerDisclosed
        self.delegate?.playerDisclosureStateChanged(isDisclosed: self.isPlayerDisclosed)
    }
}
