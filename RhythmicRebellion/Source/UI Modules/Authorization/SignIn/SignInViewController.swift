//
//  SignInViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class SignInViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    // MARK: - Public properties -

    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: SignInViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)

        #if DEBUG
        self.emailTextField.text = "alexander@olearis.com"
        self.passwordTextField.text = "ngrx2Fan"
        #else
        self.emailTextField.text = "alena@olearis.com"
        self.passwordTextField.text = "Olearistest1"
        #endif
    }

    // MARK: - Actions

    @IBAction func onSignIn(sender: Any) {

        guard let email = self.emailTextField.text, !email.isEmpty,
            let password = self.passwordTextField.text, !password.isEmpty else { return }

        self.viewModel.signIn(email: email, password: password) { (error) in
            
        }
    }

}

// MARK: - Router -
extension SignInViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}

extension SignInViewController: SignInViewModelDelegate {

    func refreshUI() {

    }

}
