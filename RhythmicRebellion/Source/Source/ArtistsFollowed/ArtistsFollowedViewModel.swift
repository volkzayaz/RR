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
    
    var dataSource: Driver<[AnimatableSectionModel<String, Artist>]> {
        return data.asDriver().map { x in
            return [AnimatableSectionModel(model: "", items: x)]
        }
    }
    
}

struct ArtistsFollowedViewModel : MVVM_ViewModel {
    
    /** Reference dependent viewModels, managers, stores, tracking variables...
     
     fileprivate let privateDependency = Dependency()
     
     fileprivate let privateTextVar = BehaviourRelay<String?>(nil)
     
     */
    
    fileprivate let searchQuery = BehaviorRelay(value: "")
    
    fileprivate let data = BehaviorRelay<[Artist]>(value: [])
    
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
        
        let dataRequest = ArtistsFollowingRequest.list.rx
            .response(type: [Artist].self)
            .trackView(viewIndicator: indicator)
            .asObservable()
        
        Observable.combineLatest(dataRequest, queryChanges) { ($0, $1) }
            .silentCatch(handler: router.owner)
            .map { arg -> [Artist] in
                
                let (artists, query) = arg
                let q = query.lowercased()
                
                guard !q.isEmpty else { return artists }
                
                return artists.filter { $0.name.lowercased().contains(q) }
                
            }
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
    
    func queryChanges(_ q: String) {
        searchQuery.accept(q)
    }
    
}
