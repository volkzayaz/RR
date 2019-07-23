//
//  PlayerMyPlaylistsControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension MyPlaylistsViewModel {
    
    var dataSource: Driver<[AnimatableSectionModel<String, TrackGroupViewModel<FanPlaylist>>]> {
        
        let r = router
        
        func renameAction(x: FanPlaylist) -> RRSheet.Action {
            return RRSheet.Action(option: .rename, action: { self.rename(playlist: x) })
        }
        
        func deleteAction(x: FanPlaylist) -> RRSheet.Action {
            return RRSheet.Action(option: .delete, action: { self.delete(playlist: x) })
        }
        
        let s = appState.map { $0.player.myPlaylists }
            .distinctUntilChanged()
        
        return Driver.combineLatest(s, searchQuery.asDriver()) { (playlists, query) in
            
                if query.isEmpty {
                    return playlists
                }
            
                return playlists.filter { $0.name.lowercased().contains(query.lowercased()) }
            }
            .map { (x: [FanPlaylist]) in
                
                let y = x.map { p in TrackGroupViewModel(router: .init(owner: r.owner!),
                                                         data: p,
                                                         extraActions: [renameAction(x: p),
                                                                        deleteAction(x: p)],
                                                         inclusionClosure: { $0.id != p.id }) }
                
            return [AnimatableSectionModel(model: "", items: y)]
        }
    }
    
}

struct MyPlaylistsViewModel {
    
    private let router: MyPlaylistsRouter
    private let searchQuery = BehaviorRelay(value: "")
    
    init(router: MyPlaylistsRouter) {
        self.router = router
        
        PlaylistRequest.fanList
            .rx.response(type: [FanPlaylist].self)
            .asObservable()
//            .silentCatch(handler: router.owner)
            .subscribe(onNext: { (x) in
                Dispatcher.dispatch(action: ReplacePlaylists(playlists: x))
            })
            .disposed(by: bag)
    
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
        
    }
    
    private let bag = DisposeBag()
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    
}

extension MyPlaylistsViewModel {
    
    func select(viewModel: TrackGroupViewModel<FanPlaylist>) {
        router.showContent(of: viewModel.data)
    }
    
    func queryChanged(q: String) {
        searchQuery.accept(q)
    }
    
    func addPlaylist() {
        
        router.owner?.showTextQuestion(with: "Create playlist",
                                       question: "Enter a name for your playlist",
                                       actionName: "Create", callback: { (name) in
                                        
                                        PlaylistRequest.create(name: name).rx.response(type: FanPlaylist.self)
                                            .silentCatch(handler: self.router.owner)
                                            .trackView(viewIndicator: self.indicator)
                                            .subscribe(onNext: { (x) in
                                                Dispatcher.dispatch(action: AppendPlaylists(playlists: [x]))
                                            })
                                            .disposed(by: self.bag)
                                        
        })
        
    }
    
    func rename(playlist: FanPlaylist) {
        
        router.owner?.showTextQuestion(with: "Rename playlist",
                                       question: "Enter a new name for this playlist",
                                       actionName: "Save", callback: { (name) in
                                        
                                        PlaylistRequest.rename(playlist: playlist, newName: name).rx.response(type: FanPlaylist.self)
                                            .silentCatch(handler: self.router.owner)
                                            .trackView(viewIndicator: self.indicator)
                                            .subscribe(onNext: { (x) in
                                                Dispatcher.dispatch(action: SubstitutePlaylist(new: x))
                                            })
                                            .disposed(by: self.bag)
                                        
        })
        
    }
    
    func delete(playlist: FanPlaylist) {
        
        Dispatcher.dispatch(action: RemovePlaylist(playlist: playlist))
        
        PlaylistRequest.delete(playlist: playlist).rx.emptyResponse()
            .silentCatch(handler: router.owner)
            .subscribe()
            .disposed(by: bag)
        
    }
}
