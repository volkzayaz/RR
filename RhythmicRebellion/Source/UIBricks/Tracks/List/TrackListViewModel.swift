//
//  TrackListViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

struct ActionViewModel: AlertActionItemViewModel {
    
    let type: ActionType
    let actionCallback: () -> Void
    
    init(_ type: ActionType, actionCallback: @escaping () -> Void) {
        self.type = type
        self.actionCallback = actionCallback
    }
    
    var title: String {
        return type.description
    }
    
    var actionStyle: UIAlertAction.Style {
        return type.actionStyle
    }
    
}

extension ActionViewModel {
    
    enum ActionType: CustomStringConvertible {
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
        
        var actionStyle: UIAlertAction.Style {
            switch self {
            case .delete: return .destructive
            case .cancel: return .cancel
            default: return .default
            }
        }
        
        var description: String {
            switch self {
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
    }
    
}

protocol TrackProvider {
    
    ////provide list of tracks to play back
    func provide() -> Observable<[TrackProvidable]>
    
}

class TrackListViewModel {

    ////provide list of actions available for given track
    typealias ActionsProvider = (TrackListViewModel, TrackProvidable) -> [ActionViewModel]

    let trackProivder: TrackProvider
    private let actionsProvider: ActionsProvider
    
    private let bag = DisposeBag()
    private let reloadTrigger = BehaviorSubject<Void>(value: () )
    
    let tracks = BehaviorRelay<[TrackProvidable]>(value: [])
    
    var trackViewModels: Driver<[TrackViewModel]> {
        
        let r = router
        
        let userChanges = appState
            .map { $0.user }
            .distinctUntilChanged()
        
        return Driver.combineLatest(tracks.asDriver(),
                                    userChanges)
            .map { [unowned self] arg in
                
                let (tracks, user) = arg
                
                return tracks.map { track in
                    
                    return TrackViewModel(router: r.trackRouter(for: track.track),
                                          trackProvidable: track,
                                          user: user,
                                          actions: self.actions(of: track, for: user))
                    
                }
                
        }
    }
    
    var isPlaylistEmpty: Bool {
        return tracks.value.isEmpty
    }
    
    init(dataProvider: TrackProvider,
         router: TrackListRouter,
         actionsProvider: @escaping ActionsProvider = { _, _ in [] }) {
        
        self.trackProivder = dataProvider
        self.router = router
        self.actionsProvider = actionsProvider

        reloadTrigger.flatMapLatest { [unowned self] _ in
            return self.trackProivder.provide()
        }
            .silentCatch(handler: router.owner)
            .bind(to: tracks)
            .disposed(by: bag)
        
    }
    
    private let router: TrackListRouter
    
}

extension TrackListViewModel {
    
    private func actions(of track: TrackProvidable, for user: User) -> AlertActionsViewModel<ActionViewModel> {
        
        let t = track
        
        let cancel = [ActionViewModel(.cancel, actionCallback: {} )]
        let actions = actionsProvider(self, t)
        
        let ftp = ActionViewModel(.forceToPlay) { [weak self] in
            self?.forceToPlay(track: t.track)
        }
        
        let dnp = ActionViewModel(.doNotPlay) { [weak self] in
            self?.doNotPlay(track: t.track)
        }
        
        var result: [ActionViewModel] = []
        
        if !user.isGuest,
            user.isCensorshipTrack(t.track) &&
            !(user.profile?.forceToPlay.contains(t.track.id) ?? false) {
            result.append(ftp)
        }
        
        if  user.isCensorshipTrack(t.track) &&
            user.profile?.forceToPlay.contains(t.track.id) ?? false {
            result.append(dnp)
        }
        
        if user.hasPurchase(for: t.track) {
            ///No proper action is available so far
            //result.append(add)
        }
        
        return AlertActionsViewModel<ActionViewModel>(title: nil,
                                                      message: nil,
                                                      actions: result + actions + cancel)
        
    }
    
}

/////////////////
/////////////////
/////---------Actions with list
/////////////////
/////////////////

extension TrackListViewModel {
    
    func forceToPlay(track: Track) {

        let _ =
        UserManager.allowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                        shouldAllow: true)
            .silentCatch(handler: router.owner)
            .subscribe()

    }

    func doNotPlay(track: Track) {
        
        let _ =
        UserManager.allowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                        shouldAllow: false)
            .silentCatch(handler: router.owner)
            .subscribe()
        
    }
    
    func reload() {
        reloadTrigger.onNext(())
    }
    
    func drop(track: TrackProvidable) {
        var x = tracks.value
        x.removeAll { $0.identity == track.identity }
        tracks.accept(x)
    }
    
    func dropAllTracks() {
        tracks.accept([])
    }
    
}


import RxDataSources

protocol TrackProvidable {
    var identity: String { get }
    var track: Track { get }
    
    func isEqualTo(orderedTrack: OrderedTrack) -> Bool
}

extension Track: TrackProvidable {
    public var identity: String { return "\(id)" }
    var track: Track { return self }
    
    func isEqualTo(orderedTrack: OrderedTrack) -> Bool {
        return orderedTrack.track == self
    }
}

extension OrderedTrack: TrackProvidable {
    var identity: String { return orderHash }
    
    func isEqualTo(orderedTrack: OrderedTrack) -> Bool {
        return orderedTrack == self
    }
}
