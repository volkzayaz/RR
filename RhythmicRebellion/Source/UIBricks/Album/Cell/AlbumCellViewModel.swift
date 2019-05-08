//
//  AlbumCellViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension AlbumCellViewModel {
    
    /** Reference binding drivers that are going to be used in the corresponding view
    
    var text: Driver<String> {
        return privateTextVar.asDriver().notNil()
    }
 
     */
    
}

struct AlbumCellViewModel : MVVM_ViewModel {
    
    struct Data: Equatable {
        let album: Album
        let artistName: String
    }; let data: Data
    
    
    init(router: AlbumCellRouter, data: Data) {
        self.router = router
        self.data = data
        
        /**
         
         Proceed with initialization here
         
         */
        
        /////progress indicator
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
    }
    
    let router: AlbumCellRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension AlbumCellViewModel {

    func presentActions() {
        
        let cancel = [ActionViewModel(.cancel, actionCallback: {} )]
        
        let a = data.album
        let bag = self.bag
        
        ///1. Load tracks for album
        let loader = { [unowned i = indicator,
                        weak r = router.owner] (x: @escaping ([Track]) -> Void) -> () -> Void in
            return {
                ArtistRequest.albumRecords(album: a)
                    .rx.baseResponse(type: [Track].self)
                    .silentCatch(handler: r)
                    .trackView(viewIndicator: i)
                    .subscribe(onNext: x)
                    .disposed(by: bag)
            }
            
        }
        
        ///2. let caller exchange [Track] for ActionCreator
        ///3. Dispatch the action
        let dispatcher = { (x: @escaping ([Track]) -> ActionCreator) -> () -> Void in
            return loader({ Dispatcher.dispatch(action: x($0)) })
        }
        
        let r = router
        let x =
            [ActionViewModel(.playNow, actionCallback: dispatcher({
                return AddTracksToLinkedPlaying(tracks: $0, style: .now)
            })),
             ActionViewModel(.playNext, actionCallback: dispatcher({
                return AddTracksToLinkedPlaying(tracks: $0, style: .next)
             })),
             ActionViewModel(.playLast, actionCallback: dispatcher({
                return AddTracksToLinkedPlaying(tracks: $0, style: .last)
             })),
             ActionViewModel(.replaceCurrent, actionCallback: dispatcher({
                return ReplaceTracks(with: $0)
             })),
             ActionViewModel(.toPlaylist, actionCallback: loader ({
                r.presentPlaylistCreation(for: $0)
             }))]
        
        router.present(actions: AlertActionsViewModel<ActionViewModel>(title: nil,
                                                                       message: nil,
                                                                       actions: x + cancel))
    }
    
}