//
//  Application.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Reachability

protocol UserCredentials {
    var email: String { get }
    var password: String { get }
}

protocol ApplicationObserver: class {
    func application(_ application: Application, didChangeUser user: User?)
}

extension ApplicationObserver {
    func application(_ application: Application, didChangeUser user: User?) { }
}

class Application: Observable {

    typealias ObserverType = ApplicationObserver

    let observersContainer = ObserversContainer<ApplicationObserver>()

    struct URI {
        static let restApiService = "http://new-ngrx.api.rebellionretailsite.com"
        static let webSocketService = "ws://new-ngrx.rebellionretailsite.com:3000/"
    }

    let restApiService: RestApiService
    let webSocketService: WebSocketService
    let player: Player

    private let restApiServiceReachability: Reachability?
    private let webSocketServiceReachability: Reachability?

    var user: User? = nil

    init?() {
        guard let restApiServiceURL = URL(string: URI.restApiService), let webSocketServiceURL = URL(string: URI.webSocketService) else { return nil }

        self.restApiService = RestApiService(serverURL: restApiServiceURL)
        self.webSocketService = WebSocketService(socketURL: webSocketServiceURL)
        self.player = Player(restApiService: restApiService, webSocketService: webSocketService)

        self.restApiServiceReachability = Reachability(hostname: restApiServiceURL.host!)
        self.webSocketServiceReachability = Reachability(hostname: webSocketServiceURL.host!)

        self.restApiServiceReachability?.whenReachable = { [unowned self] _ in
            guard self.user == nil else { return }
            self.fanUser()
        }

        self.webSocketServiceReachability?.whenReachable = { [unowned self] _ in
            self.webSocketService.isReachable = true
            guard let user = self.user else { return }
            self.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
        }

        self.webSocketServiceReachability?.whenUnreachable = { [unowned self] _ in
            self.webSocketService.isReachable = false
            self.webSocketService.disconnect()
        }
    }

    func start() {
        _ = try? self.webSocketServiceReachability?.startNotifier()
        _ = try? self.restApiServiceReachability?.startNotifier()
    }

    func fanUser() {
        guard let reachability = self.restApiServiceReachability, reachability.connection != .none else { return }

        self.restApiService.fanUser { [weak self] (fanUserResult) in

            switch (fanUserResult) {
            case .success(let user):
                self?.user = user
                self?.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
                self?.notifyUserChanged()

            case .failure(let error):
                print("FanUser error: \(error)")
            }
        }

    }

    func login(with credentials: UserCredentials) {
        guard let reachability = self.restApiServiceReachability, reachability.connection != .none else { return }

        self.restApiService.fanLogin(email: credentials.email, password: credentials.password, completion: { [weak self] (loginUserResult) in

            switch (loginUserResult) {
            case .success(let user):
                self?.user = user
                self?.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
                self?.notifyUserChanged()
                

            case .failure(let error):
                print("FanUser error: \(error)")
            }
        })
    }
}

extension Application {

    func notifyUserChanged() {
        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChangeUser: self.user)
        })
    }
}
