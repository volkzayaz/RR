//
//  HomeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/17/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension HomeViewModel {
    
    var dataSource: Driver<[AnimatableSectionModel<String, TrackGroupViewModel<DefinedPlaylist>>]> {
        return data.asDriver().map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

final class HomeViewModel {
    
    // MARK: - Private properties -
    
    private let router: HomeRouter
    
    fileprivate let data = BehaviorRelay<[TrackGroupViewModel<DefinedPlaylist>]>(value: [])
    
    // MARK: - Lifecycle -
    
    init(router: HomeRouter) {
        self.router = router
        
        PlaylistRequest.rrList
            .rx.response(type: [DefinedPlaylist].self)
            .asObservable()
            .silentCatch(handler: router.owner)
            .map { $0.map { TrackGroupViewModel(router: .init(owner: router.owner!),
                                                data: $0) } }
            .bind(to: data)
            .disposed(by: bag)
        
    }
    
    private let bag = DisposeBag()
    
}

extension HomeViewModel {
    
    func select(viewModel: TrackGroupViewModel<DefinedPlaylist>) {
        router.showContent(of: viewModel.data)
    }
    
}
