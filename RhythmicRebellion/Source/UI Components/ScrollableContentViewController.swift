//
//  ScrollableContentViewController.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol ScrollableContentViewController: class {

    var scrollView: UIScrollView! { get }

    var keyboardWillShowObserver: NSObjectProtocol? { get set }
    var keyboardWillHideObserver: NSObjectProtocol? { get set }
}

extension ScrollableContentViewController where Self: UIViewController {

    func startObserveKeyboard() {

        self.keyboardWillShowObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in

            guard let keyboardFrameValue: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

            let keyboardFrame = self.view.convert(keyboardFrameValue.cgRectValue, from: nil)

            let bottomInset = self.scrollView.frame.maxY - keyboardFrame.minY
            if bottomInset > 0 {
                let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
            }
        }

        self.keyboardWillHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [unowned  self] (notification) in

            self.scrollView.contentInset = .zero
            self.scrollView.scrollIndicatorInsets = .zero
        }
    }

    func stopObserveKeyboard() {

        if let keyboardWillShowObserver = self.keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
            self.keyboardWillShowObserver = nil
        }

        if let keyboardWillHideObserver = self.keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
            self.keyboardWillHideObserver = nil
        }

    }
}
