//
//  PromoControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/27/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
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
                
                return state.user?.isAddonsSkipped(for: t.artist)
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
    
    var canToggleSkipAddons: Driver<Bool> {
        return appState.distinctUntilChanged { $0.currentTrack?.track == $0.currentTrack?.track }
            .map { (state) -> Bool? in
            
                guard state.currentTrack?.track != nil else { return nil }
                
                return state.user?.isGuest
            }
            .notNil()
    }
    
    // MARK: - Private properties -

    private(set) weak var delegate: PromoViewModelDelegate?
    private(set) weak var router: PromoRouter?

    private(set) var application: Application

    private var currentTrack: Driver<Track> {
        return appState.map { $0.currentTrack?.track }
            .notNil()
            .distinctUntilChanged()
    }


    // MARK: - Lifecycle -

    deinit {
        self.application.removeWatcher(self)
    }

    init(router: PromoRouter, application: Application) {
        self.router = router
        self.application = application
    }

    func load(with delegate: PromoViewModelDelegate) {
        self.delegate = delegate

        self.delegate?.refreshUI()

        self.application.addWatcher(self)       
    }

    func thumbnailURL() -> URL? {
        guard let track = appStateSlice.currentTrack?.track else { return nil }
        return track.thumbnailURL(with: [.thumb, .small, .medium, .xsmall, .original, .big, .large, .xlarge, .preload])
    }

    func setSkipAddons(skip: Bool) {
        guard let artist = appStateSlice.currentTrack?.track.artist else { self.delegate?.refreshUI(); return }

        self.application.updateSkipAddons(for: artist, skip: skip)
            .subscribe(onError: { [weak self] (error) in
                self?.delegate?.show(error: error)
            })
        
    }

    func navigateToPage(with url: URL) {
        self.router?.navigateToPage(with: url)
    }

    func visitArtistSite() {
        guard let artistURL = appStateSlice.currentTrack?.track.artist.url else { return }
 
        self.navigateToPage(with: artistURL)
    }

    func visitWriterSite() {
        guard let writerURL = appStateSlice.currentTrack?.track.writer.url else { return }

        self.navigateToPage(with: writerURL)
    }

    func routeToAuthorization() {
        self.router?.routeToAuthorization(with: .signIn)
    }
}

extension PromoViewModel {

    func player(didChangePlayerItem playerItem: Void /*PlayerItem?*/) {
        self.delegate?.refreshUI()
    }
}

extension PromoViewModel: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState) {
        guard skipArtistAddonsState.artistId == appStateSlice.currentTrack?.track.artist.id else { return }

        //self.delegate?.refreshUI()
    }
}
