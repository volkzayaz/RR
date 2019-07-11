//
//  PromoControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import RxSwift
import RxCocoa

final class PromoViewModel {

    var artistName: Driver<String> {
        return currentTrack.map { $0.artist.name }
    }
    
    var trackName: Driver<String> {
        return currentTrack.map { $0.name }
    }
    
    var infoText: Driver<String> {
        return currentTrack.map { $0.radioInfo }
    }

    var writerName: Driver<String> {
        return currentTrack.map { $0.writer.name }
    }
    
    var isAddonsSkipped: Driver<Bool> {
        
        return appState.distinctUntilChanged { $0.currentTrack?.track == $0.currentTrack?.track }
            .map { (state) -> Bool? in
                
                guard let t = state.currentTrack?.track else { return nil }
                
                return state.user.isAddonsSkipped(for: t.artist)
            }
            .notNil()
        
    }

    var canVisitArtistSite: Driver<Bool> {
        return currentTrack.map { t in
            return t.artist.url != nil && t.artist.publishDate != nil
        }
    }
    
    var canVisitWriterSite: Driver<Bool> {
        return currentTrack.map { t in
            return t.artist.url != nil && t.writer.publishDate != nil
        }
    }
    
    var canToggleSkipAddons: Driver<Bool> { return .just(true) }
//        return appState.distinctUntilChanged { $0.currentTrack?.track == $0.currentTrack?.track }
//            .map { (state) -> Bool? in
//
//                guard state.currentTrack?.track != nil else { return nil }
//
//                return !state.user.isGuest
//            }
//            .notNil()
//    }
    
    // MARK: - Private properties -

    private let router: PromoRouter?

    

    private var currentTrack: Driver<Track> {
        return appState.map { $0.currentTrack?.track }
            .notNil()
            .distinctUntilChanged()
    }


    // MARK: - Lifecycle -

    init(router: PromoRouter) {
        self.router = router
        
    }

    private let bag = DisposeBag()
    
    func thumbnailURL() -> URL? {
        guard let track = appStateSlice.currentTrack?.track else { return nil }
        return track.thumbnailURL(with: [.thumb, .small, .medium, .xsmall, .original, .big, .large, .xlarge, .preload])
    }

    func setSkipAddons(skip: Bool) {
        guard !appStateSlice.user.isGuest else {
            
            ////TODO: kill it with fire!!
            router?.owner.dismissController()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToSignIn"), object: nil)
            
            return
        }
        
        guard let artist = appStateSlice.currentTrack?.track.artist else { return }

        UserManager.updateSkipAddons(for: artist, skip: skip)
            .silentCatch(handler: router?.owner)
            .subscribe()
            .disposed(by: bag)
        
    }

    func navigateToPage(with url: URL) {
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "navigateToPage"), object: nil, userInfo: ["url": url])
        
    }

    func visitArtistSite() {
        guard let artistURL = appStateSlice.currentTrack?.track.artist.url else { return }
 
        self.navigateToPage(with: artistURL)
    }

    func visitWriterSite() {
        guard let writerURL = appStateSlice.currentTrack?.track.writer.url else { return }

        self.navigateToPage(with: writerURL)
    }

}
