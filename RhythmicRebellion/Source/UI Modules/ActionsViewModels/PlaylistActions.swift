//
//  PlaylistActions.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

enum PlaylistActionsViewModels {

    typealias ViewModel = AlertActionsViewModel<PlaylistActionsViewModels.ActionViewModel>

    static var allActionsTypes: [ActionViewModel.ActionType] {
        return [
            .playNow,
            .playNext,
            .playLast,
            .replaceCurrent,
            .toPlaylist,
            .delete
        ]
    }

    struct Factory {

        func makeActionsViewModels(actionTypes: [ActionViewModel.ActionType], actionCallback: @escaping (ActionViewModel.ActionType) -> Void) -> [ActionViewModel] {
            let actionsViewModels = actionTypes.map { actionType in
                ActionViewModel(actionType, actionCallback: { actionCallback(actionType) })
            }

            return actionsViewModels + [ActionViewModel(.cancel, actionCallback: { } )]
        }
    }

    struct ActionViewModel: AlertActionItemViewModel {

        typealias ActionName = ActionType

        enum ActionType {
            case playNow
            case playNext
            case playLast
            case replaceCurrent
            case toPlaylist
            case clear
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
            case .playNow:  return NSLocalizedString("Play Now", comment: "Play Now playlist action title")
            case .playNext: return NSLocalizedString("Play Next", comment: "Play Next playlist action title")
            case .playLast: return NSLocalizedString("Play Last", comment: "playLast playlist action title")
            case .replaceCurrent: return NSLocalizedString("Replace current", comment: "Replace current playlist action title")
            case .toPlaylist: return NSLocalizedString("To Playlist", comment: "To Playlist playlist action title")
            case .clear: return NSLocalizedString("Clear", comment: "Clear playlist action title")
            case .delete: return NSLocalizedString("Delete Playlist", comment: "Delete playlist action title")
            case .cancel: return NSLocalizedString("Cancel", comment: "Cancel action title")
            }
        }

        var actionStyle: UIAlertAction.Style {
            switch type {
            case .delete: return .destructive
            case .cancel: return .cancel
            default: return .default
            }
        }
    }
}
