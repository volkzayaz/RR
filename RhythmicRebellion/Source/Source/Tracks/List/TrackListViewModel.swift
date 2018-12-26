//
//  TrackListViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TrackListBindings: class, ErrorPresenting {
    
    func reloadUI()
    func reloadPlaylistUI()
    
    func reloadObjects(at indexPath: [IndexPath])
}

protocol TrackProvider {
    
    ////provide list of tracks to play back
    func provide( competion: (Box<[Track]>) -> Void )
    
    ////provide list of actions available for given track
    func actions(for track: Track) -> [ActionViewModel]
    
    ///handle track selection
    var selected: (Track, IndexPath) -> Void { get }
    
}

class TrackListViewModel {
 
    private weak var delegate: PlayerNowPlayingViewModelDelegate?
    private weak var router: PlayerNowPlayingRouter?
    private weak var application: Application?
    private weak var player: Player?
    private weak var audioFileLocalStorageService: AudioFileLocalStorageService?
    
    private let textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
    private let trackPriceFormatter = MoneyFormatter()
    
    private let trackProivder: TrackProvider
    private var tracks: [Track] = [] {
        didSet {
            delegate?.reloadUI()
            delegate?.reloadPlaylistUI()
        }
    }
    
    var isPlaylistEmpty: Bool {
        return tracks.isEmpty
    }
    
    // MARK: - Lifecycle -
    
    deinit {
        self.application?.removeWatcher(self)
        self.player?.removeWatcher(self)
        self.audioFileLocalStorageService?.removeWatcher(self)
    }
    
    init(router: PlayerNowPlayingRouter,
         application: Application,
         player: Player,
         audioFileLocalStorageService: AudioFileLocalStorageService,
         provider: TrackProvider) {
        self.router = router
        self.application = application
        self.player = player
        self.audioFileLocalStorageService = audioFileLocalStorageService
        trackProivder = provider
    }
    
}



extension TrackListViewModel {
    
    func load(with delegate: PlayerNowPlayingViewModelDelegate) {
        self.delegate = delegate
        
        self.loadItems()
        self.application?.addWatcher(self)
        self.player?.addWatcher(self)
        self.audioFileLocalStorageService?.addWatcher(self)
    }
    
    func loadItems() {
        
        trackProivder.provide { [weak self] result in
            
            switch result {
                
            case .value(let val):
                self?.tracks = val
                
            case .error(let er):
                self?.delegate?.show(error: er, completion: { [weak self] in self?.delegate?.reloadUI() } )
                
            }
            
        }
        
    }
    
}

/////////////////
/////////////////
/////---------DataSource
/////////////////
/////////////////

extension TrackListViewModel {
    
    func numberOfItems(in section: Int) -> Int {
        return tracks.count
    }
    
    func object(at indexPath: IndexPath) -> TrackViewModel {
        
        let track = tracks[indexPath.row]
        
        return TrackViewModel(track: track,
                              user: application?.user,
                              player: player,
                              audioFileLocalStorageService: audioFileLocalStorageService,
                              textImageGenerator: textImageGenerator,
                              isCurrentInPlayer: player?.currentItem?.playlistItem.track == track,
                              isLockedForActions: false)
    }
    
    func selectObject(at indexPath: IndexPath) {
        
        let viewModel = object(at: indexPath)
        guard viewModel.isPlayable else {
            return
        }
        
        trackProivder.selected( tracks[indexPath.row], indexPath )
        
    }
    
}

extension TrackListViewModel {
    
    func actions(forObjectAt indexPath: IndexPath) -> AlertActionsViewModel<ActionViewModel> {
        
        let track = tracks[indexPath.row]
        
        return AlertActionsViewModel<ActionViewModel>(title: nil,
                                                      message: nil,
                                                      actions: trackProivder.actions(for: track))
        
    }
    
}



/////////////////
/////////////////
/////---------Downloading audio
/////////////////
/////////////////




extension TrackListViewModel {
    
    func downloadObject(at indexPath: IndexPath) {
        guard indexPath.item < tracks.count,
              let trackAudioFile = tracks[indexPath.item].audioFile else { return }
        
        self.audioFileLocalStorageService?.download(trackAudioFile: trackAudioFile)
    }
    
    func cancelDownloadingObject(at indexPath: IndexPath) {
        guard indexPath.item < tracks.count,
            let trackAudioFile = tracks[indexPath.item].audioFile else { return }
        
        self.audioFileLocalStorageService?.cancelDownloading(for: trackAudioFile)
    }
    
    func objectLoaclURL(at indexPath: IndexPath) -> URL? {
        guard indexPath.item < tracks.count,
            let trackAudioFile = tracks[indexPath.item].audioFile,
            let state = self.audioFileLocalStorageService?.state(for: trackAudioFile) else { return nil }
        
        switch state {
        case .downloaded(let localURL): return localURL
        default: return nil
        }
    }
}



/////////////////
/////////////////
/////---------User profile changed
/////////////////
/////////////////





extension TrackListViewModel: ApplicationObserver {
    
    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard track.artist.id == artistFollowingState.artistId else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) {
        
        var changedPurchasedTracksIds = Array(added)
        changedPurchasedTracksIds.append(contentsOf: removed)
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard changedPurchasedTracksIds.contains(track.id) else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
}

/////////////////
/////////////////
/////---------Global player state
/////////////////
/////////////////

extension TrackListViewModel: PlayerObserver {
    
    func playerDidChangePlaylist(player: Player) {
        self.loadItems()
    }
    
    func player(player: Player, didChange status: PlayerStatus) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval) {
        
        guard let playerCurrentTrack = self.player?.currentItem?.playlistItem.track else { return }
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard track.id == playerCurrentTrack.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    
    func player(player: Player, didChangeBlockedState isBlocked: Bool) {
        self.delegate?.reloadUI()
    }
}

/////////////////
/////////////////
/////---------Audio downloading state change
/////////////////
/////////////////

extension TrackListViewModel: AudioFileLocalStorageServiceObserver {
    
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
    
    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {
        
        var indexPaths: [IndexPath] = []
        
        for (index, track) in tracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}
