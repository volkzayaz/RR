//
//  TrackListViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit

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


protocol TrackListBindings: class, ErrorPresenting, AlertActionsViewModelPersenting, ConfirmationPresenting {
    
    func reloadUI()
    func reloadPlaylistUI()
    
    func reloadObjects(at indexPath: [IndexPath])
}

protocol TrackProvider {
    
    ////provide list of tracks to play back
    func provide() -> Observable<[TrackProvidable]>
    
}

class TrackListViewModel {

    ////provide list of actions available for given track
    typealias ActionsProvider = (TrackListViewModel, TrackProvidable, IndexPath) -> [ActionViewModel]
    
    ///handle track selection
    typealias SelectedProvider = (TrackListViewModel, TrackProvidable, IndexPath) -> Void

    private(set) weak var delegate: TrackListBindings?
    private weak var application: Application?
    
    private let textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
    private let trackPriceFormatter = MoneyFormatter()
    
    let trackProivder: TrackProvider
    private let router: TrackListRouter
    private let selectedProvider: SelectedProvider
    private let actionsProvider: ActionsProvider
    
    private let bag = DisposeBag()
    private let reloadTrigger = BehaviorSubject<Void>(value: () )
    
    private(set) var tracks: [TrackProvidable] = [] {
        didSet {
            delegate?.reloadUI()
            delegate?.reloadPlaylistUI()
        }
    }
    
    var isPlaylistEmpty: Bool {
        return tracks.isEmpty
    }
    
    deinit {
        self.application?.removeWatcher(self)
    }
    
    init(application: Application,
         dataProvider: TrackProvider,
         router: TrackListRouter,
         actionsProvider: @escaping ActionsProvider = { _, _, _ in [] },
         selectedProvider: @escaping SelectedProvider = { _, _, _ in }) {
    
        self.application = application
        
        self.trackProivder = dataProvider
        self.router = router
        self.selectedProvider = selectedProvider
        self.actionsProvider = actionsProvider

    }
    
}

extension TrackListViewModel {
    
    func load(with delegate: TrackListBindings) {
        self.delegate = delegate
        
        self.application?.addWatcher(self)
        
        reloadTrigger.flatMapLatest { [unowned self] _ in
                return self.trackProivder.provide()
            }
            .subscribe(onNext: { [weak self] (tracks) in
                self?.tracks = tracks
            }, onError: { [weak self] (er) in
                self?.delegate?.show(error: er, completion: { [weak self] in self?.delegate?.reloadUI() } )
            })
            .disposed(by: bag)
        
    }
    
}

/////////////////
/////////////////
/////---------DataSource
/////////////////
/////////////////

extension TrackListViewModel {
    
    func numberOfItems(in section: Int) -> Int {
        return tracks.count
    }
    
    func object(at indexPath: IndexPath) -> TrackViewModel {
        
        let track = tracks[indexPath.row]
        
        return trackViewModel(for: track)
    }
    
    func trackViewModel(for track: TrackProvidable) -> TrackViewModel {
        
        return TrackViewModel(router: router.trackRouter(for: track.track),
                              trackProvidable: track,
                              user: application?.user,
                              textImageGenerator: textImageGenerator)
        
    }
    
    func selectObject(at indexPath: IndexPath) {
        
        let viewModel = object(at: indexPath)
        guard viewModel.isPlayable else {
            return
        }
        
        selectedProvider(self, tracks[indexPath.row], indexPath)
        
    }
    
}

extension TrackListViewModel {
    
    func actions(forObjectAt indexPath: IndexPath) -> AlertActionsViewModel<ActionViewModel> {
        
        let t = tracks[indexPath.row]
        
        let cancel = [ActionViewModel(.cancel, actionCallback: {} )]
        let actions = actionsProvider(self, t, indexPath)
        
        let ftp = ActionViewModel(.forceToPlay) { [weak self] in
            self?.forceToPlay(track: t.track)
        }
        
        let dnp = ActionViewModel(.doNotPlay) { [weak self] in
            self?.doNotPlay(track: t.track)
        }
        
        let maybeUser = application?.user as? FanUser
        
        var result: [ActionViewModel] = []
        
        if let user = maybeUser,
            user.isCensorshipTrack(t.track) &&
                !user.profile.forceToPlay.contains(t.track.id) {
            result.append(ftp)
        }
        
        if let user = maybeUser,
            user.isCensorshipTrack(t.track) &&
                user.profile.forceToPlay.contains(t.track.id) {
            result.append(dnp)
        }
        
        if let user = maybeUser,
            user.hasPurchase(for: t.track) {
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
        
        application?.allowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                completion: { [weak self] res in
                                                    if case .failure(let error) = res {
                                                        self?.delegate?.show(error: error)
                                                    }
            })
    }

    func doNotPlay(track: Track) {
        
        application?.disallowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                        completion: { [weak self] res in
                                                            if case .failure(let error) = res {
                                                                self?.delegate?.show(error: error)
                                                            }
        })
    }
    
    func play(orderedTrack: OrderedTrack) {
        DataLayer.get.daPlayer.switch(to: orderedTrack)
    }
    
    func remove(orderedTrack: OrderedTrack) {
        DataLayer.get.daPlayer.remove(track: orderedTrack)
    }
    
    func play(tracks: [Track], at style: RRPlayer.AddStyle = .now) {
        DataLayer.get.daPlayer.add(tracks: tracks, type: style)
    }
    
    func replacePlayerPlaylist(with tracks: [Track]) {
        
        fatalError("Replace unimplemented")
        
        ///we don't know how to alter AppState, when repace happens
        ///specifically, what do we do with reduxViewPatches
        
//        guard tracks.isEmpty == false else { return }
//
//        self.player?.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
//            guard let error = error else { return }
//            self?.delegate?.show(error: error)
//        })
        
    }
    
    func reload() {
        reloadTrigger.onNext(())
    }
    
    func dropTrack(at index: Int) {
        var x = tracks
        x.remove(at: index)
        tracks = x
    }
    
    func dropAllTracks() {
        tracks = []
    }
    
}


/////////////////
/////////////////
/////---------User profile changed
/////////////////
/////////////////


extension TrackListViewModel: ApplicationWatcher {
    
    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        
        var indexPaths: [IndexPath] = []
        
        for (index, t) in tracks.enumerated() {
            guard t.track.artist.id == artistFollowingState.artistId else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) {
        
        var changedPurchasedTracksIds = Array(added)
        changedPurchasedTracksIds.append(contentsOf: removed)
        
        var indexPaths: [IndexPath] = []
        
        for (index, t) in tracks.enumerated() {
            guard changedPurchasedTracksIds.contains(t.track.id) else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        self.delegate?.reloadUI()
    }
    
}

import RxSwift

extension TrackListViewModel {
    
    class Observer: TrackListBindings {
        
        typealias Handler = NSObjectProtocol & ErrorPresenting & AlertActionsViewModelPersenting & ConfirmationPresenting
        
        var trackViewModels: Observable<[TrackViewModel]> {
            return subject.asObservable()
        }
        
        let trackList: TrackListViewModel
        weak var handler: Handler?
        init(list: TrackListViewModel, handler: Handler) {
            trackList = list
            self.handler = handler
            
            list.load(with: self)
        }
        
        fileprivate let subject = BehaviorSubject<[TrackViewModel]>(value: [])
        
        func reloadUI() {
            subject.onNext( trackList.tracks.map { self.trackList.trackViewModel(for: $0) } )
        }
        
        func reloadPlaylistUI() {
            subject.onNext( trackList.tracks.map { self.trackList.trackViewModel(for: $0) } )
        }
        
        func reloadObjects(at indexPath: [IndexPath]) {
            subject.onNext( trackList.tracks.map { self.trackList.trackViewModel(for: $0) } )
        }
    
        
        
        func show(error: Error) { handler?.show(error: error) }
        func show(error: Error, completion: (() -> Void)?) { handler?.show(error: error, completion: completion) }
        
        func show<T>(alertActionsviewModel: AlertActionsViewModel<T>) { handler?.show(alertActionsviewModel: alertActionsviewModel) }
        func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style) { handler?.show(alertActionsviewModel: alertActionsviewModel, style: style) }
        func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, style: UIAlertController.Style, completion: (() -> Void)?) { handler?.show(alertActionsviewModel: alertActionsviewModel, style: style, completion: completion) }
        
        func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView) { handler?.show(alertActionsviewModel: alertActionsviewModel, sourceRect: sourceRect, sourceView: sourceView) }
        func show<T>(alertActionsviewModel: AlertActionsViewModel<T>, sourceRect: CGRect, sourceView: UIView, completion: (() -> Void)?) { handler?.show(alertActionsviewModel: alertActionsviewModel, sourceRect: sourceRect, sourceView: sourceView, completion: completion) }
        
        func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>) { handler?.showConfirmation(confirmationViewModel: confirmationViewModel) }
        func showConfirmation(confirmationViewModel: AlertActionsViewModel<ConfirmationAlertViewModel.ActionViewModel>, completion: (() -> Void)?) { handler?.showConfirmation(confirmationViewModel: confirmationViewModel, completion: completion) }
        
    }
    
    
    
}

import RxDataSources

protocol TrackProvidable {
    var identity: String { get }
    var track: Track { get }
}

extension Track: TrackProvidable {
    public var identity: String { return "\(id)" }
    var track: Track { return self }
}

extension OrderedTrack: TrackProvidable {
    var identity: String {
        return orderHash
    }
}
