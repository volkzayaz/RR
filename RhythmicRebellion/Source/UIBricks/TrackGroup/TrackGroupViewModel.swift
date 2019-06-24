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
        var x =
            [
             RRSheet.Action(option: .playNow, action: dispatcher {
                return AddTracksToLinkedPlaying(tracks: $0, style: .now)
             }),
             RRSheet.Action(option: .playNext, action: dispatcher {
                return AddTracksToLinkedPlaying(tracks: $0, style: .next)
             }),
             RRSheet.Action(option: .playLater, action: dispatcher {
                return AddTracksToLinkedPlaying(tracks: $0, style: .last)
             }),
             RRSheet.Action(option: .replace, action: dispatcher {
                return ReplaceTracks(with: $0)
             })
             ]
        
        if !appStateSlice.user.isGuest {
            x.append(RRSheet.Action(option: .addToLibrary, action: loader {
                r.presentPlaylistCreation(for: $0)
            }))
        }
        
        router.present(actions: x)
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
