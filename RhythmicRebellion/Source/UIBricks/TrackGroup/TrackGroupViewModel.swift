//
//  TrackGroupViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/8/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

extension TrackGroupViewModel {
    
    /** Reference binding drivers that are going to be used in the corresponding view
    
    var text: Driver<String> {
        return privateTextVar.asDriver().notNil()
    }
 
     */
    
}

///entity that can represent group of tracks
///for example album or playlist
protocol TrackGroupPresentable {
    
    ///what identifies your entityt among others
    ///for example for Album it might be AlbumID
    ///or combination of Artist name and Album name
    var identity: String { get }
    
    ///Name of your entity
    ///Will be used to display in the first row of corresponding cell
    var name: String { get }
    
    ///Additional description of your entity
    ///Will be used to display in the secod row of corresponding cell
    var subtitle: String { get }
    
    ///Image used as cover of your entity
    var imageURL: String { get }
    
    ///Upon user perfoming actions like "playNext" or "to custom playlist"
    ///provide the list of tracks that represent your entity
    ///for exaplme an Album would return a list of [Track] in this Album
    var underlineTracks: Maybe<[Track]> { get }
}

struct TrackGroupViewModel<T: TrackGroupPresentable> : MVVM_ViewModel, TrackGroupViewModelProtocol {
    
    let data: T
    
    init(router: TrackGroupCellRouter, data: T) {
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
    
    let router: TrackGroupCellRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
 
    var present: TrackGroupPresentable {
        return data
    }
    
}

extension TrackGroupViewModel {

    func presentActions() {
        
        let cancel = [ActionViewModel(.cancel, actionCallback: {} )]
        
        let data = self.data
        let bag = self.bag
        
        ///1. Load tracks for album
        let loader = { [unowned i = indicator,
                        weak r = router.owner] (x: @escaping ([Track]) -> Void) -> () -> Void in
            return {
                data.underlineTracks
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

extension TrackGroupViewModel: Equatable, IdentifiableType {
    
    static func ==(lhs: TrackGroupViewModel<T>, rhs: TrackGroupViewModel<T>) -> Bool {
        return lhs.data.identity == rhs.data.identity
    }
    
    var identity: String {
        return data.identity
    }
}
