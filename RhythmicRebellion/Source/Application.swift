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
        static let restApiService = "http://mobile.api.rebellionretailsite.com"
        static let webSocketService = "ws://mobile.rebellionretailsite.com:3000/"
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

    func signIn(with credentials: UserCredentials, completion: ((Error?) -> Void)? = nil) {

        self.restApiService.fanLogin(email: credentials.email, password: credentials.password, completion: { [weak self] (loginUserResult) in

            switch (loginUserResult) {
            case .success(let user):
                self?.user = user
                self?.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
                self?.notifyUserChanged()
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        })
    }

    func logout() {
        guard let user = self.user, user.isGuest == false, let reachability = self.restApiServiceReachability, reachability.connection != .none else { return }

        self.restApiService.fanLogout { [weak self] (logoutUserResult) in
            switch (logoutUserResult) {
            case .success(let user):
                self?.webSocketService.disconnect()
                self?.user = user
                self?.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
                self?.notifyUserChanged()

            case .failure(let error):
                print("FanUser error: \(error)")
            }
        }
    }
}

extension Application {

    func notifyUserChanged() {
        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChangeUser: self.user)
        })
    }
}
