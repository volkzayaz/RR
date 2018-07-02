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

        self.restApiService?.getFanUser(completion: { [unowned self] (user) in
            self.user = user
            if let user = user {
                self.webSocketService?.connect(with: user.wsToken)
            }
        })
    }

    func togglePlayerDisclosure() {
        self.isPlayerDisclosed = !self.isPlayerDisclosed
        self.delegate?.playerDisclosureStateChanged(isDisclosed: self.isPlayerDisclosed)
    }
}
