//
//  Application.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import Reachability
import Alamofire

protocol UserCredentials {
    var email: String { get }
    var password: String { get }
}

protocol ApplicationObserver: class {
    func application(_ application: Application, didChange user: User)
    func application(_ application: Application, didChange listeningSettings: ListeningSettings)
    func application(_ application: Application, didChange profile: UserProfile)
}

extension ApplicationObserver {
    func application(_ application: Application, didChange user: User) { }
    func application(_ application: Application, didChange listeningSettings: ListeningSettings) { }
    func application(_ application: Application, didChange profile: UserProfile) { }
}

class Application: Observable {

    typealias ObserverType = ApplicationObserver

    let observersContainer = ObserversContainer<ApplicationObserver>()

    struct URI {

        //http://mobile.fan.rebellionretailsite.com/

        static let origin = "http://dev-mobile.fan.rebellionretailsite.com"
        static let restApiService = "http://dev-mobile.api.rebellionretailsite.com"
        static let webSocketService = "ws://dev-mobile.rebellionretailsite.com:3000/"
    }

    let restApiService: RestApiService
    let webSocketService: WebSocketService
    let player: Player

    private let restApiServiceReachability: Reachability?
    private let webSocketServiceReachability: Reachability?

    var user: User? = nil

    init?() {
        guard let restApiServiceURL = URL(string: URI.restApiService), let webSocketServiceURL = URL(string: URI.webSocketService) else { return nil }

        self.restApiService = RestApiService(serverURL: restApiServiceURL, originURI: URI.origin)
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

        self.addObserver(self.player)
    }

    func start() {
        _ = try? self.webSocketServiceReachability?.startNotifier()
        _ = try? self.restApiServiceReachability?.startNotifier()
    }



    func set(user: User) {

        guard let prevUser = self.user else {
            self.user = user
            self.notifyUserChanged()
            return
        }

        self.user = user

        if prevUser != user {
            self.notifyUserChanged()
        } else {
            if let prevFanUser = prevUser as? FanUser,
                    let fanUser = user as? FanUser,
                prevFanUser.profile != fanUser.profile {

                self.notifyUserProfileChanged()
            }

            if self.webSocketService.token?.token != user.wsToken {
                self.webSocketService.token = Token(token: user.wsToken, isGuest: user.isGuest)
            }
        }
    }

    func fanUser(completion: ((Result<User>) -> Void)? = nil) {
        self.restApiService.fanUser { [weak self] (fanUserResult) in

            switch (fanUserResult) {
            case .success(let user):
                self?.set(user: user)
                completion?(.success(user))

            case .failure(let error):
                completion?(.failure(error))
            }
        }

    }

    func signIn(with credentials: UserCredentials, completion: ((Error?) -> Void)? = nil) {

        self.restApiService.fanLogin(email: credentials.email, password: credentials.password, completion: { [weak self] (loginUserResult) in

            switch (loginUserResult) {
            case .success(let user):
                self?.set(user: user)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        })
    }

    func logout(completion: ((Error?) -> Void)? = nil) {
        guard let user = self.user, user.isGuest == false else { return }

        self.restApiService.fanLogout { [weak self] (logoutUserResult) in
            switch logoutUserResult {
            case .success(let user):
                self?.set(user: user)
                completion?(nil)

            case .failure(let error):
                completion?(error)
            }
        }
    }

    func update(listeningSettings: ListeningSettings, completion: ((Result<ListeningSettings>) -> Void)? = nil) {

        guard let user = self.user, user.isGuest == false else { return }

        let listeningSettingsRequestPayload = RestApiListeningSettingsRequestPayload(with: listeningSettings)

        self.restApiService.fanUser(update: listeningSettingsRequestPayload) { [weak self] (updateUserResult) in

            switch updateUserResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { completion?(.failure(AppError("Unexpected Server response"))); return }

                self?.set(user: user)
                self?.notifyListeningSettingsChanged()
                completion?(.success(fanUser.profile.listeningSettings))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    func update(profileSettings: UserProfile, completion: ((Result<UserProfile>) -> Void)? = nil) {

        guard let user = self.user, user.isGuest == false else { return }

        let profileSettingsRequestPayload = RestApiProfileSettingsRequestPayload(with: profileSettings)

        self.restApiService.fanUser(update: profileSettingsRequestPayload) { [weak self] (updateUserResult) in

            switch updateUserResult {
            case .success(let user):
                guard let fanUser = user as? FanUser else { completion?(.failure(AppError("Unexpected Server response"))); return }

                self?.set(user: user)
                completion?(.success(fanUser.profile))

            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

}

extension Application {

    func notifyUserChanged() {

        guard let user = self.user else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: user)
        })
    }

    func notifyListeningSettingsChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: fanUser.profile.listeningSettings)
        })
    }

    func notifyUserProfileChanged() {
        guard let fanUser = self.user as? FanUser else { return }

        self.observersContainer.invoke({ (observer) in
            observer.application(self, didChange: fanUser.profile)
        })
    }

}
