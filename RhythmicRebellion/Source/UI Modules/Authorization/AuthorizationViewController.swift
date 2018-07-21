//
//  AuthorizationViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class AuthorizationViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Public properties -

    private(set) var viewModel: AuthorizationViewModel!
    private(set) var router: FlowRouter!

    private var keyboardWillShowObserver: NSObjectProtocol?
    private var keyboardWillHideObserver: NSObjectProtocol?

    // MARK: - Configuration -

    func configure(viewModel: AuthorizationViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    deinit {
        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.load(with: self)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardDidShow, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
                self.keyboardDidShow(notification: notification)
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in
            self.keyboardWillHide(notification: notification)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }
    }


    override func systemLayoutFittingSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.systemLayoutFittingSizeDidChange(forChildContentContainer: container)

        print("container.preferredContentSize = \(container.preferredContentSize)")

        self.containerViewHeightConstraint.constant = container.preferredContentSize.height
    }

    // MARK: - Notifications
    func keyboardDidShow(notification: Notification) {
        guard let keyboardFrameValue: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)

        let bottomInset = self.view.bounds.maxY - keyboardFrame.minY
        if bottomInset > 0 {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
        }
    }

    func keyboardWillHide(notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

}

// MARK: - Router -
extension AuthorizationViewController {

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

extension AuthorizationViewController: AuthorizationViewModelDelegate {

    func refreshUI() {

    }

}
