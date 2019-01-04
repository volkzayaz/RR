//
//  AlertViewModel.swift
//  Folia
//
//  Created by Andrew on 7/19/17.
//  Copyright © 2017 Branchfire. All rights reserved.
//

import UIKit

protocol AlertActionItemViewModel {

    associatedtype ActionName

    var actionCallback: () -> Void { get }

    var type: ActionName { get }

    var title: String { get }

    var actionStyle: UIAlertAction.Style { get }
}


struct AlertActionsViewModel<T: AlertActionItemViewModel> {
    let title: String?
    let message: String?
    let actions: [T]
}

extension UIAlertController {

    class func make<T>(from viewModel: AlertActionsViewModel<T>,
                       style: UIAlertController.Style = .actionSheet,
                       onAction: @escaping (T) -> Void = { _ in}) -> UIAlertController {

        let alertController = UIAlertController(title: viewModel.title, message: viewModel.message, preferredStyle: style)

        viewModel
            .actions
            .compactMap { action in
                UIAlertAction(title: action.title, style: action.actionStyle) { _ in
                    action.actionCallback()
                    onAction(action)
                }
            }
            .forEach(alertController.addAction)

        return alertController
    }
}

protocol AlertActionsViewModelPersenting {

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>)
    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style)
    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style, completion: (() -> Void)?)

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView)
    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView, completion: (() -> Void)?)
}

extension UIViewController: AlertActionsViewModelPersenting {

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>) {
        show(alertActionsviewModel: alertActionsviewModel, style: .actionSheet)
    }

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style) {
        show(alertActionsviewModel: alertActionsviewModel, style: style, completion: nil)
    }

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style, completion: (() -> Void)? = nil) {

        let alertActionsController = UIAlertController.make(from: alertActionsviewModel, style: style)

        self.present(alertActionsController, animated: true, completion: completion)
    }

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView) {
        show(alertActionsviewModel: alertActionsviewModel, sourceRect: sourceRect, sourceView: sourceView, completion: nil)
    }

    func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView, completion: (() -> Void)?) {

        let alertActionsController = UIAlertController.make(from: alertActionsviewModel, style: .actionSheet)

        alertActionsController.popoverPresentationController?.sourceRect = sourceRect
        alertActionsController.popoverPresentationController?.sourceView = sourceView

        self.present(alertActionsController, animated: true, completion: completion)
    }

}
