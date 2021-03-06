//
//  SignInControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator
import Alamofire

import RxSwift
import RxCocoa

protocol SignInViewModelDelegate: class, ErrorPresenting {
    
    func refreshUI()
    
    func refreshEmailField(field: ValidatableField, didValidate error: ValidationError?)
    func refreshPasswordField(field: ValidatableField, didValidate error: ValidationError?)
    
    func refreshEmailField(with email: String?)
}


final class SignInViewModel {

    // MARK: - Public properties

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041702, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) weak var delegate: SignInViewModelDelegate?
    private(set) weak var router: SignInRouter?
    

    private(set) var signInErrorDescription: String?

    private let validator: Validator
    private var emailField: ValidatableField?
    private var passwordField: ValidatableField?

    // MARK: - Lifecycle -

    init(router: SignInRouter) {
        self.router = router
        
        self.validator = Validator()
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.sourceController] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }

    func load(with delegate: SignInViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            if validationRule.field === self.emailField {
                self.delegate?.refreshEmailField(field: validationRule.field, didValidate: nil)
            } else if validationRule.field === self.passwordField {
                self.delegate?.refreshPasswordField(field: validationRule.field, didValidate: nil)
            }
        }, error:{ (validationError) -> Void in
            if validationError.field === self.emailField {
                self.delegate?.refreshEmailField(field: validationError.field, didValidate: validationError)
            } else if validationError.field === self.passwordField {
                self.delegate?.refreshPasswordField(field: validationError.field, didValidate: validationError)
            }
        })

        self.delegate?.refreshUI()
    }

    func registerEmailField(emailField: ValidatableField) {

        self.emailField = emailField
        let emailRules: [Rule] = [RequiredRule(message: "The field is required"),
                                  EmailRule(message: "Email is wrong")]
        self.validator.registerField(emailField, rules: emailRules)

        if emailField.validationText.isEmpty == true {
            self.delegate?.refreshEmailField(with: SettingsStore.lastSignedUserEmail.value)
            self.delegate?.refreshEmailField(field: emailField, didValidate: nil)
        } else {
            self.validator.validateField(emailField) { (validationError) in }
        }
    }

    func registerPasswordField(passwordField: ValidatableField) {
        self.passwordField = passwordField
        let passwordRules: [Rule] = [RequiredRule(message: "The password field is required")]
        self.validator.registerField(passwordField, rules: passwordRules)

        self.delegate?.refreshPasswordField(field: passwordField, didValidate: nil)
    }

    func validateField(field: ValidatableField) {
        self.validator.validateField(field) { (validationError) in }
    }

    func resorePassword() {
        self.router?.showRestorePassword(email: self.emailField?.validationText)
    }

    func signIn() {
        
        #if DEBUG
        if let e = self.emailField?.validationText, e.starts(with: "#") {

            SettingsStore.environment.value = String(e.dropFirst())
            HTTPCookieStorage.shared.removeCookies(since: Date(timeIntervalSince1970: 0))
            
            UIAlertView(title: "Success", message: "Changed environment to \(e.dropFirst()). Reload application to start using it.", delegate: nil, cancelButtonTitle: "Ok").show()
            
            return
        }
        #endif
        
        
        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText, let password = self.passwordField?.validationText else { return }

            DataLayer.get.pagesLocalStorageService.reset()
            
            let _ =
            UserRequest.signIn(login: email, password: password)
                .rx.response(type: FanLoginResponse.self)
                .subscribe(onSuccess: { (resp) in
                    
                    Dispatcher.dispatch(action: SetNewUser(user: resp.user))
                    
                }, onError: { error in
                    
                    guard let appError = error as? RRError,
                        case .server(let e) = appError, let email = e.errors["email"]?.first else {
                        self.delegate?.show(error: error)
                        return
                    }
                    
                    self.signInErrorDescription = email
                    self.delegate?.refreshUI()
                    
                })
            
        }
    }
    
    var authenticator = FacebookAuthenticator()
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
    func joinWithFacebook() {
        
        authenticator = FacebookAuthenticator()
        
        authenticator.authenticateUser(onController: router!.sourceController!)
            .flatMap { [unowned nav = router!.sourceController!.navigationController!] (data) -> Observable<FanLoginResponse> in
                
                guard case .external(let provider) = data else {
                    return Observable<FanLoginResponse?>.just(nil).notNil()
                }
                
                ////Welcome to the world of Excelent and Easy authorization with facebook:
                ////If you've got the facebook token you just need:
                ////1) poke login endpoint with the token. (Seems legit 😎)
                ////2) backend might tell you that user is not registered. 😢
                ////3) push register enpoint with the token. (Not cool, second roundtrip, but let's roll 😕)
                ////4) backend might tell you that there isn't sufficient details to create user (💩)
                ////5) you are expected to collect details from user and push them to register enpoint yet again 💩💩💩
                ////Easy, ain't it? ¯\_(ツ)_/¯
                
                return UserRequest.externalLogin(provider: provider).rx.response(type: FanLoginResponse.self)
                    .asObservable()
                    .catchError { (error) -> Observable<FanLoginResponse> in
                        
                        if case .server(let e)? = error as? RRError, e.code == 403 {
                            return UserRequest.externalRegister(provider: provider)
                                .rx.response(type: FanLoginResponse.self)
                                .asObservable()
                        }
                        
                        throw error
                        
                    }
                    .catchError { (error) -> Observable<FanLoginResponse> in
                        
                        if case .server(let e)? = error as? RRError, e.errors.count > 1 {
                            
                            let vc = R.storyboard.authorization.continueFacebookRegistrationViewController()!
                            let vm = ContinueFacebookRegistrationViewModel(router: .init(owner: vc), facebookToken: provider.accessToken)
                            vc.viewModel = vm
                            
                            nav.pushViewController(vc, animated: false)
                            
                            return Observable<FanLoginResponse?>.just(nil).notNil()
                        }
                        
                        throw error
                        
                    }
            }
            .trackView(viewIndicator: indicator)
            .silentCatch(handler: router!.sourceController!)
            .subscribe(onNext: { (resp) in
                
                DataLayer.get.pagesLocalStorageService.reset()
                
                Dispatcher.dispatch(action: SetNewUser(user: resp.user))
                
            })
            .disposed(by: bag)
        
    }

    func restart() {
        self.router?.restart()
    }
}
