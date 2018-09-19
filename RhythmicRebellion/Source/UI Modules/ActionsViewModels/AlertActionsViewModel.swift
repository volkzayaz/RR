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

    var actionStyle: UIAlertActionStyle { get }
}


struct AlertActionsViewModel<T: AlertActionItemViewModel> {
    let title: String?
    let message: String?
    let actions: [T]
}

extension UIAlertController {

    class func make<T>(from viewModel: AlertActionsViewModel<T>,
                       style: UIAlertControllerStyle = .actionSheet,
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
