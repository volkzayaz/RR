//
//  SkipChangesConfirmation.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

enum ConfirmationAlertViewModel {

    typealias ViewModel = AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>


    struct Factory {

        static func makeActionsViewModels(actionTypes: [ActionViewModel.ActionType], actionCallback: @escaping (ActionViewModel.ActionType) -> Void) -> [ActionViewModel] {
            let actionsViewModels = actionTypes.map { actionType in
                ActionViewModel(actionType, actionCallback: { actionCallback(actionType) })
            }

            return actionsViewModels + [ActionViewModel(.cancel, actionCallback: { } )]
        }

        static func makeSkipProfileChangesViewModel(actionCallback: @escaping (ActionViewModel.ActionType) -> Void) -> ViewModel {

            let actions = makeActionsViewModels(actionTypes: [.ok], actionCallback: actionCallback)

            return ViewModel(title: Title.warning.text, message: Message.profileUnsavedChanges.text, actions: actions)
        }

        static func makeClearPlaylistViewModel(actionCallback: @escaping (ActionViewModel.ActionType) -> Void) -> ViewModel {

            let actions = makeActionsViewModels(actionTypes: [.ok], actionCallback: actionCallback)

            return ViewModel(title: Title.warning.text, message: Message.clearPlaylist.text, actions: actions)
        }

        static func makeDeletePlaylistViewModel(actionCallback: @escaping (ActionViewModel.ActionType) -> Void) -> ViewModel {

            let actions = makeActionsViewModels(actionTypes: [.ok], actionCallback: actionCallback)

            return ViewModel(title: Title.warning.text, message: Message.deletePlaylist.text, actions: actions)
        }

    }

    struct Title {

        let text: String

        public init(_ text: String) {
            self.text = text
        }

        static let warning = Title(NSLocalizedString("Warning", comment: "Warning alert title"))
    }

    struct Message {

        let text: String

        public init(_ text: String) {
            self.text = text
        }

        static let profileUnsavedChanges = Message(NSLocalizedString("You have unsaved changes. Press Cancel to go back and save these changes,or OK to lose these changes.",
                                                                     comment: "Unsaved changes message"))

        static let clearPlaylist = Message(NSLocalizedString("Are you sure you want to clear playlist? All data from it will be removed.",
                                                             comment: "Unsaved changes message"))

        static let deletePlaylist = Message(NSLocalizedString("Are you sure you want to delete playlist? All data from it will be removed.",
                                                              comment: "Unsaved changes message"))
    }

    struct ActionViewModel: AlertActionItemViewModel {
        typealias ActionName = ActionType

        enum ActionType {
            case ok
            case delete
            case cancel
        }

        let type: ActionType
        let actionCallback: () -> Void

        init(_ type: ActionType, actionCallback: @escaping () -> Void) {
            self.type = type
            self.actionCallback = actionCallback
        }

        var title: String {
            switch type {
            case .ok:  return NSLocalizedString("OK", comment: "Ok action title")
            case .delete: return NSLocalizedString("Delete", comment: "Delete track action title")
            case .cancel: return NSLocalizedString("Cancel", comment: "Cancel action title")
            }
        }

        var actionStyle: UIAlertActionStyle {
            switch type {
            case .delete: return .destructive
            case .cancel: return .cancel
            default: return .default
            }
        }
    }
}

protocol ConfirmationPresenting {

    func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>)
    func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>, completion: (() -> Void)?)
}

extension AlertActionsViewModelPersenting where Self: UIViewController {

    func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>) {
        self.showConfirmation(confirmationViewModel: confirmationViewModel, completion: nil)
    }

    func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>, completion: (() -> Void)?) {
        let alertActionsController = UIAlertController.make(from: confirmationViewModel, style: .alert)

        self.present(alertActionsController, animated: true, completion: completion)

    }
}
