//
//  AppControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Reachability

final class AppControllerViewModel: AppViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: AppViewModelDelegate?
    private(set) weak var router: AppRouter?

    private(set) weak var restApiService: RestApiService?
    private(set) weak var webSocketService: WebSocketService?

    private let reachability: Reachability? = Reachability()

    var isPlayerDisclosed: Bool = false

    #if DEBUG
        let email = "alexander@olearis.com"
        let password = "ngrx2Fan"
    #else
        let email = "alena@olearis.com"
        let password = "Olearistest1"
    #endif
    var user: User?

    // MARK: - Lifecycle -

    init(router: AppRouter, restApiService: RestApiService, webSocketService: WebSocketService) {
        self.router = router
        self.restApiService = restApiService
        self.webSocketService = webSocketService

        self.reachability?.whenReachable = { [unowned self] _ in
            DispatchQueue.main.async { [unowned self] in
                self.webSocketService?.isReachable = true
                guard let user = self.user else { self.login(); return }
                self.webSocketService?.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
            }
        }
        reachability?.whenUnreachable = { [unowned self] _ in
            DispatchQueue.main.async { [unowned self] in
                self.webSocketService?.isReachable = false
            }
        }
    }

    func load(with delegate: AppViewModelDelegate) {
        self.delegate = delegate

        _ = try? reachability?.startNotifier()


    }

    func login() {
        guard let reachability = self.reachability, reachability.connection != .none else { return }

        self.restApiService?.fanLogin(email: email, password: password, completion: { [weak self] (user) in
            self?.user = user
            if let user = self?.user {
                self?.webSocketService?.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
            }
        })
    }

    func togglePlayerDisclosure() {
        self.isPlayerDisclosed = !self.isPlayerDisclosed
        self.delegate?.playerDisclosureStateChanged(isDisclosed: self.isPlayerDisclosed)
    }
}
