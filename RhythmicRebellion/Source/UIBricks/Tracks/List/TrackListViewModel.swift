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

class TrackListViewModel {

    ////provide list of actions available for given track
    typealias ActionsProvider = (TrackListViewModel, TrackRepresentation) -> [RRSheet.Action]

    let trackProivder: TrackProvider
    private let actionsProvider: ActionsProvider
    
    private let bag = DisposeBag()
    private let reloadTrigger = BehaviorSubject<Void>(value: () )
    
    //private
    let tracks = BehaviorRelay<[TrackRepresentation]>(value: [])
    
    var trackViewModels: Driver<[TrackViewModel]> {
        
        let r = router
        let m = trackProivder.mode
        
        let userChanges = appState
            .map { $0.user }
            .distinctUntilChanged()
        
        return Driver.combineLatest(tracks.asDriver(),
                                    userChanges)
            .map { [unowned self] arg in
                
                let (tracks, user) = arg
                
                return tracks.map { track in
                    
                    return TrackViewModel(router: r.trackRouter(for: track.track),
                                          trackRepresentation: track,
                                          mode: m,
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
         actionsProvider: @escaping ActionsProvider) {
        
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
    
    private func actions(of track: TrackRepresentation, for user: User) -> [RRSheet.Action] {
        
        let t = track
        
        let actions = actionsProvider(self, t)
        
        let ftp = RRSheet.Action(option: .forceToPlay) { [weak self] in
            self?.forceToPlay(track: t.track)
        }
        
        let dnp = RRSheet.Action(option: .doNotPlay) { [weak self] in
            self?.doNotPlay(track: t.track)
        }
        
        var result: [RRSheet.Action] = []
        
        if t.track.isCensorship, let p = user.profile, !p.forceToPlay.contains(t.track.id) {
            result.append(ftp)
        }
        
        if t.track.isCensorship, let p = user.profile, p.forceToPlay.contains(t.track.id) {
            result.append(dnp)
        }
        
        if user.hasPurchase(for: t.track) {
            ///No proper action is available so far
            //result.append(add)
        }
        
        return result + actions
        
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
    
    func drop(track: TrackRepresentation) {
        var x = tracks.value
        x.removeAll { $0.identity == track.identity }
        let y = x.enumerated().map { (i, element) -> TrackRepresentation in
            var e = element
            e.index = i
            return e
        }
        tracks.accept(y)
    }
    
    func dropAllTracks() {
        tracks.accept([])
    }
    
}

import RxDataSources

protocol TrackProvidable {
    var track: Track { get }
    
    func isSame(with orderedTrack: OrderedTrack) -> Bool
}

struct TrackRepresentation: Equatable, IdentifiableType {
    
    let identity: String
    var index: Int
    let providable: TrackProvidable
    
    init(index: Int, track: Track) {
        self.providable = track
        self.index = index
        
        self.identity = "\(track.id)"
    }
    
    init(orderedTrack: OrderedTrack) {
        self.providable = orderedTrack
        self.index = 0
        
        self.identity = orderedTrack.orderHash
    }
    
    var track: Track { return providable.track }
    
    static func ==(lhs: TrackRepresentation, rhs: TrackRepresentation) -> Bool {
        return lhs.index == rhs.index && lhs.track == rhs.track
    }
}

extension Track: TrackProvidable {
    var track: Track { return self }
    
    func isSame(with orderedTrack: OrderedTrack) -> Bool {
        return self == orderedTrack.track
    }
}

extension OrderedTrack: TrackProvidable {
    func isSame(with orderedTrack: OrderedTrack) -> Bool {
        return self.orderHash == orderedTrack.orderHash
    }
}
