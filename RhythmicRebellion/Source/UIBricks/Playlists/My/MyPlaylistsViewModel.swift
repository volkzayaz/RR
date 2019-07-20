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
        return appState.map { $0.player.myPlaylists }
            .distinctUntilChanged()
            .map { x in
                
                let y = x.map { p in TrackGroupViewModel(router: .init(owner: r.owner!),
                                                         data: p,
                                                         inclusionClosure: { $0.id != p.id }) }
                
            return [AnimatableSectionModel(model: "", items: y)]
        }
    }
    
}

final class MyPlaylistsViewModel {
    
    // MARK: - Private properties -
    
    private let router: MyPlaylistsRouter
    
    // MARK: - Lifecycle -
    
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
        
    }
    
    private let bag = DisposeBag()
    
}

extension MyPlaylistsViewModel {
    
    func select(viewModel: TrackGroupViewModel<FanPlaylist>) {
        router.showContent(of: viewModel.data)
    }
    
}
