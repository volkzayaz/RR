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
    
    ///upon unfollowing directly from dataSource
    ///we will not wait until socket signals us
    ///we will directly remove corresponding artist from the datasource
    fileprivate let quickUnfollowBuffer = BehaviorSubject<ArtistFollowingState?>(value: nil)
    
    init(router: ArtistsFollowedRouter) {
        self.router = router
        
        let queryChanges = searchQuery.asObservable()
            .distinctUntilChanged()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .filter { q in
                guard q.lengthOfBytes(using: String.Encoding.utf8) < 3 else { return true }
                
                ///if (q == 0 || q > 2)
                
                return q.lengthOfBytes(using: String.Encoding.utf8) == 0
            }
        
        let listUpdated = DataLayer.get.application.followingState
        
        let artistUnfollowed = listUpdated.filter { !$0.isFollowed }
        let artistFollowed   = listUpdated.filter {  $0.isFollowed }
        
        let dataRequest = ArtistsFollowingRequest.list.rx
            .response(type: [Artist].self)
            .trackView(viewIndicator: indicator)
            .asObservable()
        
        artistFollowed.map { _ in }
            .startWith( () )
            .flatMapLatest { [unowned buffer = quickUnfollowBuffer] _ -> Observable<([Artist], [String], String)> in
                
                let filterOutArtists = Observable.of( buffer.asObservable().skip(1).notNil(),
                                                      artistUnfollowed)
                    .merge()
                    .scan([], accumulator: { $0 + [$1.artistId] })
                    .startWith([])
                
                return Observable.combineLatest(dataRequest,
                                                filterOutArtists, queryChanges) { ($0, $1, $2) }
            }
            .map { arg -> [Artist] in
                
                let (artists, kicked, query) = arg
                
                let list = artists.filter { !kicked.contains($0.id) }
                
                let q = query.lowercased()
                
                guard !q.isEmpty else { return list }
                
                return list.filter { $0.name.lowercased().contains(q) }
                
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
        
        quickUnfollowBuffer.onNext( ArtistFollowingState(artistId: artist.id,
                                                         isFollowed: false) )
        ///TODO: migrate to reactive error handling
        DataLayer.get.application.unfollow(artistId: artist.id) { [weak m = router.owner] (res) in
            if case .failure(let e) = res {
                m?.presentError(error: e)
            }
        }
        
    }
    
    func select(artist: Artist) {
        router.presentArtist(artist: artist)
    }
    
}
