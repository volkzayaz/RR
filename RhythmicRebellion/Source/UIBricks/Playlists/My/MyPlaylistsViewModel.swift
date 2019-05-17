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
        return data.asDriver().map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

final class MyPlaylistsViewModel {
    
    // MARK: - Private properties -
    
    private let router: MyPlaylistsRouter
    
    fileprivate let data = BehaviorRelay<[TrackGroupViewModel<FanPlaylist>]>(value: [])
    
    // MARK: - Lifecycle -
    
    init(router: MyPlaylistsRouter) {
        self.router = router
        
        PlaylistRequest.fanList
            .rx.response(type: [FanPlaylist].self)
            .asObservable()
            .silentCatch(handler: router.owner)
            .map { $0.map { TrackGroupViewModel(router: .init(owner: router.owner!),
                                                data: $0) } }
            .bind(to: data)
            .disposed(by: bag)
        
    }
    
    private let bag = DisposeBag()
    
}

extension MyPlaylistsViewModel {
    
    func select(viewModel: TrackGroupViewModel<FanPlaylist>) {
        router.showContent(of: viewModel.data)
    }
    
}
