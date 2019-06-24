//
//  AddToPlaylistControllerViewModel.swift
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

import Alamofire

extension AddToPlaylistViewModel {
    
    enum Row: IdentifiableType, Equatable {
        case create
        case playlist(FanPlaylist)
        
        var identity: String {
            switch self {
            case .create: return "create"
            case .playlist(let x): return x.identity
            }
        }
    }
    
    var dataSource: Driver<[AnimatableSectionModel<String, Row>]> {
        return appState.map { $0.player.myPlaylists }
            .distinctUntilChanged()
            .map { x in
                return [AnimatableSectionModel(model: "", items: [.create] + x.map { Row.playlist($0) })]
            }
    }
    
}

struct AddToPlaylistViewModel {

    // MARK: - Private properties -

    private let router: AddToPlaylistRouter
    
    private(set) var playlists: [FanPlaylist] = [FanPlaylist]()
    private let attachable: AttachableProvider
    
    init(router: AddToPlaylistRouter, attachable: AttachableProvider) {
        self.router = router
        self.attachable = attachable
        
        PlaylistRequest.fanList
            .rx.response(type: [FanPlaylist].self)
            .silentCatch(handler: router.owner)
            .subscribe(onNext: { x in
                Dispatcher.dispatch(action: ReplacePlaylists(playlists: x))
            })
            .disposed(by: bag)
        
    }
    
    private let bag = DisposeBag()

}

extension AddToPlaylistViewModel {
    
    func select(playlist: FanPlaylist) {
        
        let r = router
        attachable.attach(to: playlist)
            .catchError({ (error) -> Maybe<Void> in
                
                if let e = error as? AFError, e.responseCode == 422 {
                    throw RRError.generic(message: "This track has been already added to this playlist")
                }
                
                throw error
            })
            .silentCatch(handler: router.owner)
            .subscribe(onNext: {
                r.dismiss()
            })
            .disposed(by: bag)
        
    }
    
    func cancel() {
        router.dismiss()
    }
    
    func createPlaylist(with name: String) {
        
        PlaylistManager.createPlaylist(with: name)
            .silentCatch(handler: router.owner)
            .subscribe(onNext: { playlist in
                Dispatcher.dispatch(action: AppendPlaylists(playlists: [playlist]))
            })
            .disposed(by: bag)
        
    }
    
}
