//
//  ProfileControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

enum ProfileItem: Int {
    case profileSettings = 0
    case changeEmail
    case changePassword

    var name: String {
        switch self {
        case .profileSettings: return NSLocalizedString("Profile Settings", comment: "Profile Settings title")
        case .changeEmail: return NSLocalizedString("Change Email", comment: "Change Email title")
        case .changePassword: return NSLocalizedString("Change Password", comment: "Change Password title")
        }
    }
}

final class ProfileControllerViewModel: ProfileViewModel {

    var userName: String { return self.fanUser?.profile?.nickname ?? "" }

    // MARK: - Private properties -

    private(set) weak var delegate: ProfileViewModelDelegate?
    private(set) weak var router: ProfileRouter?
    private(set) weak var application: Application?

    private var fanUser: User?
    private var profileItems: [ProfileItem]

    // MARK: - Lifecycle -

    init(router: ProfileRouter, application: Application) {
        self.router = router
        self.application = application

        self.profileItems = []
    }

    deinit {
        self.application?.removeWatcher(self)
    }

    func load(with delegate: ProfileViewModelDelegate) {
        guard application?.user?.isGuest ?? true == false else { return }

        self.delegate = delegate
        self.application?.addWatcher(self)

        self.fanUser = application?.user
        self.profileItems = [.profileSettings, .changeEmail, .changePassword]

        self.delegate?.reloadUI()

        self.loadUser()

    }

    func loadUser() {
        
        let _ =
        UserRequest.login.rx.baseResponse(type: User.self)
            .subscribe(onSuccess: { (user) in
                self.fanUser = user
                self.delegate?.refreshUI()
            }, onError: { error in
                self.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.refreshUI() })
            })
        
    }

    func numberOfItems(in section: Int) -> Int {
        return self.profileItems.count
    }

    func object(at indexPath: IndexPath) -> ProfileItemViewModel? {
        guard self.profileItems.count > indexPath.row else { return nil }

        return ProfileItemViewModel(with: self.profileItems[indexPath.row])
    }

    func selectObject(at indexPath: IndexPath) {
        guard self.profileItems.count > indexPath.row else { return }

        switch self.profileItems[indexPath.row] {
        case .profileSettings: self.router?.navigateToProfileSettings()
        case .changeEmail: self.router?.navigateToChangeEmail()
        case .changePassword: self.router?.navigateToChangePassword()
        }
    }

    // MARK: - Actions
    func reload() {
        self.loadUser()
    }

    func logout() {
        
        let _ =
        UserRequest.logout.rx.baseResponse(type: User.self)
            .subscribe(onSuccess: { guestUser in
                Dispatcher.dispatch(action: SetNewUser(user: guestUser))
            }, onError: { error in
                self.delegate?.show(error: error)
            })
        
    }
}

extension ProfileControllerViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile profile: UserProfile) {

        guard !(application.user?.isGuest ?? true) else { return }

        self.fanUser = application.user
        self.delegate?.refreshUI()
    }
}
