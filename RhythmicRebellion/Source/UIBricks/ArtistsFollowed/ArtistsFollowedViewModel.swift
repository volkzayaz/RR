//
//  ArtistsFollowedViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension ArtistsFollowedViewModel {
    
    /////-------
    /////Bindings
    /////-------
    
    var dataSource: Driver<[AnimatableSectionModel<String, Artist>]> {
        return data.asDriver().map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

struct ArtistsFollowedViewModel : MVVM_ViewModel {
    
    /** dependent viewModels, managers, stores, tracking variables...
     */
    
    fileprivate let searchQuery = BehaviorRelay(value: "")
    fileprivate let data = BehaviorRelay<[Artist]>(value: [])
    
    init(router: ArtistsFollowedRouter) {
        self.router = router
        
        let queryChanges = searchQuery.asObservable()
            .distinctUntilChanged()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .filter { q in
                guard q.lengthOfBytes(using: .utf8) < 3 else { return true }
                
                ///if (q == 0 || q > 2)
                
                return q.isEmpty
            }
        
        let listUpdated = appState.map { $0.user.profile?.followedArtistsIds }
                                .notNil()
                                .distinctUntilChanged()
                                .asObservable()
        
        let dataRequest = ArtistsFollowingRequest.list.rx
            .response(type: [Artist].self)
            .trackView(viewIndicator: indicator)
            .asObservable()
        
        listUpdated.distinctUntilChanged { (prev: Set<String>, next: Set<String>) -> Bool in
                return next.isSubset(of: next) == false ///new items are contained within followed Set
            }
            .flatMapLatest { followedArtists -> Observable<([Artist], String)> in
                
                return Observable.combineLatest(dataRequest, queryChanges, listUpdated)
                    .map { args in
                        return (args.0.filter { args.2.contains($0.id) }, args.1)
                    }
            }
            .map { arg -> [Artist] in
                
                let (artists, query) = arg
                
                let q = query.lowercased()
                
                guard !q.isEmpty else { return artists }
                
                return artists.filter { $0.name.lowercased().contains(q) }
                
            }
            .silentCatch(handler: router.owner)
            .bind(to: data)
            .disposed(by: bag)
            
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: ArtistsFollowedRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension ArtistsFollowedViewModel {
    
    ////------
    ////Actions
    ////------
    
    func queryChanges(_ q: String) {
        searchQuery.accept(q)
    }
 
    func unfollow(artist: Artist) {
        
        let _ =
        DataLayer.get.application.follow(shouldFollow: false,
                                         artistId: artist.id)
            .silentCatch(handler: router.owner)
            .subscribe()
        
    }
    
    func select(artist: Artist) {
        router.presentArtist(artist: artist)
    }
    
}
