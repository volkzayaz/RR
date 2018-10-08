//
//  TrackActions.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

enum TrackActionsViewModels {

    typealias ViewModel = AlertActionsViewModel<TrackActionsViewModels.ActionViewModel>

    static var allActionsTypes: [ActionViewModel.ActionType] {
        return [
                .forceToPlay,
                .doNotPlay,
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
            case forceToPlay
            case doNotPlay
            case playNow
            case playNext
            case playLast
            case replaceCurrent
            case toPlaylist
            case delete
            case cancel
            case addToCart(String)
        }

        let type: ActionType
        let actionCallback: () -> Void

        init(_ type: ActionType, actionCallback: @escaping () -> Void) {
            self.type = type
            self.actionCallback = actionCallback
        }

        var title: String {
            switch type {
            case .forceToPlay: return NSLocalizedString("Force To Play", comment: "Force To Play track action title")
            case .doNotPlay: return NSLocalizedString("Do Not Play", comment: "Do Not Play track action title")
            case .playNow:  return NSLocalizedString("Play Now", comment: "Play Now track action title")
            case .playNext: return NSLocalizedString("Play Next", comment: "Play Next track action title")
            case .playLast: return NSLocalizedString("Play Last", comment: "playLast track action title")
            case .replaceCurrent: return NSLocalizedString("Replace current", comment: "Replace current track action title")
            case .toPlaylist: return NSLocalizedString("To Playlist", comment: "To Playlist track action title")
            case .addToCart(let priceStringValue):
                let titleFormat = NSLocalizedString("Add To Cart %@", comment: "Add To Cart track action title format")
                return String(format: titleFormat, priceStringValue)
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
