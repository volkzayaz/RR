//
//  TrackListViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 12/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import UIKit

struct ActionViewModel: AlertActionItemViewModel {
    
    let type: ActionType
    let actionCallback: () -> Void
    
    init(_ type: ActionType, actionCallback: @escaping () -> Void) {
        self.type = type
        self.actionCallback = actionCallback
    }
    
    var title: String {
        return type.description
    }
    
    var actionStyle: UIAlertAction.Style {
        return type.actionStyle
    }
    
    static var allTypes: [ActionViewModel.ActionType] {
        return [
            .forceToPlay,
            .doNotPlay,
            .playNow,
            .playNext,
            .playLast,
            .replaceCurrent,
            .toPlaylist,
            .delete
        ]
    }
}

extension ActionViewModel {
    
    enum ActionType: CustomStringConvertible {
        case forceToPlay
        case doNotPlay
        case playNow
        case playNext
        case playLast
        case replaceCurrent
        case toPlaylist
        case delete
        case cancel
        case addToCart(String)
        
        var actionStyle: UIAlertAction.Style {
            switch self {
            case .delete: return .destructive
            case .cancel: return .cancel
            default: return .default
            }
        }
        
        var description: String {
            switch self {
            case .forceToPlay: return NSLocalizedString("Force To Play", comment: "Force To Play track action title")
            case .doNotPlay: return NSLocalizedString("Do Not Play", comment: "Do Not Play track action title")
            case .playNow:  return NSLocalizedString("Play Now", comment: "Play Now track action title")
            case .playNext: return NSLocalizedString("Play Next", comment: "Play Next track action title")
            case .playLast: return NSLocalizedString("Play Last", comment: "playLast track action title")
            case .replaceCurrent: return NSLocalizedString("Replace current", comment: "Replace current track action title")
            case .toPlaylist: return NSLocalizedString("To Playlist", comment: "To Playlist track action title")
            case .addToCart(let priceStringValue):
                let titleFormat = NSLocalizedString("Add To Cart %@", comment: "Add To Cart track action title format")
                return String(format: titleFormat, priceStringValue)
            case .delete: return NSLocalizedString("Delete", comment: "Delete track action title")
            case .cancel: return NSLocalizedString("Cancel", comment: "Cancel action title")
            }
        }
    }
    
}


protocol TrackListBindings: class, ErrorPresenting, AlertActionsViewModelPersenting, ConfirmationPresenting {
    
    func reloadUI()
    func reloadPlaylistUI()
    
    func reloadObjects(at indexPath: [IndexPath])
}

protocol TrackProvider {
    
    ////provide list of tracks to play back
    func provide( completion: @escaping (Box<[Track]>) -> Void )
    
}

class TrackListViewModel {

    ////provide list of actions available for given track
    typealias ActionsProvider = (TrackListViewModel, Track, IndexPath) -> [ActionViewModel]
    
    ///handle track selection
    typealias SelectedProvider = (TrackListViewModel, Track, IndexPath) -> Void

    
    private(set) weak var delegate: TrackListBindings?
    private weak var application: Application?
    private weak var player: Player?
    private weak var audioFileLocalStorageService: AudioFileLocalStorageService?
    
    private let textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
    private let trackPriceFormatter = MoneyFormatter()
    
    let trackProivder: TrackProvider
    private let selectedProvider: SelectedProvider
    private let actionsProvider: ActionsProvider
    
    private(set) var tracks: [Track] = [] {
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
    
    init(application: Application,
         player: Player,
         audioFileLocalStorageService: AudioFileLocalStorageService,
         dataProvider: TrackProvider,
         actionsProvider: @escaping ActionsProvider = { _, _, _ in [] },
         selectedProvider: @escaping SelectedProvider = { _, _, _ in }) {
    
        self.application = application
        self.player = player
        self.audioFileLocalStorageService = audioFileLocalStorageService
        
        self.trackProivder = dataProvider
        self.selectedProvider = selectedProvider
        self.actionsProvider = actionsProvider
    }
    
}

extension TrackListViewModel {
    
    func load(with delegate: TrackListBindings) {
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
                              isLockedForActions: false) //self.lockedPlaylistItemsIds.contains(track.id)
    }
    
    func selectObject(at indexPath: IndexPath) {
        
        let viewModel = object(at: indexPath)
        guard viewModel.isPlayable else {
            return
        }
        
        selectedProvider(self, tracks[indexPath.row], indexPath)
        
    }
    
}

extension TrackListViewModel {
    
    func actions(forObjectAt indexPath: IndexPath) -> AlertActionsViewModel<ActionViewModel> {
        
        let track = tracks[indexPath.row]
        
        let cancel = [ActionViewModel(.cancel, actionCallback: {} )]
        let actions = actionsProvider(self, track, indexPath)
        
        let ftp = ActionViewModel(.forceToPlay) { [weak self] in
            self?.forceToPlay(track: track)
        }
        
        let dnp = ActionViewModel(.doNotPlay) { [weak self] in
            self?.doNotPlay(track: track)
        }
        
        let maybeUser = application?.user as? FanUser
        
        var result: [ActionViewModel] = []
        
        if let user = maybeUser,
            user.isCensorshipTrack(track) &&
                !user.profile.forceToPlay.contains(track.id) {
            result.append(ftp)
        }
        
        if let user = maybeUser,
            user.isCensorshipTrack(track) &&
                user.profile.forceToPlay.contains(track.id) {
            result.append(dnp)
        }
        
        if let user = maybeUser,
            user.hasPurchase(for: track) {
            ///No proper action is available so far
            //result.append(add)
        }
        
        return AlertActionsViewModel<ActionViewModel>(title: nil,
                                                      message: nil,
                                                      actions: result + actions + cancel)
        
    }
    
}

/////////////////
/////////////////
/////---------Actions with list
/////////////////
/////////////////

extension TrackListViewModel {
    
    func forceToPlay(track: Track) {
        
        application?.allowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                completion: { [weak self] res in
                                                    if case .failure(let error) = res {
                                                        self?.delegate?.show(error: error)
                                                    }
            })
    }

    func doNotPlay(track: Track) {
        
        application?.disallowPlayTrackWithExplicitMaterial(trackId: track.id,
                                                        completion: { [weak self] res in
                                                            if case .failure(let error) = res {
                                                                self?.delegate?.show(error: error)
                                                            }
        })
    }
    
    func play(playlistItem: PlayerPlaylistItem) {
        
        self.player?.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
        
    }
    
    func delete(playlistItem: PlayerPlaylistItem) {
        player?.performAction(.delete,
                              for: playlistItem,
                              completion: { [weak self] (error) in
                                guard let error = error else { return }
                                self?.delegate?.show(error: error)
        })
    }
    
    
    
    func play(tracks: [Track]) {
        
        self.player?.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard let playlistItem = playlistItems?.first else {
                guard let error = error else { return }
                self?.delegate?.show(error: error)
                return
            }
            
            self?.play(playlistItem: playlistItem)
        })
    }
    
    func addToPlayerPlaylist(tracks: [Track], at position: Player.PlaylistPosition) {
        guard tracks.isEmpty == false else { return }
        
        self.player?.add(tracks: tracks, at: position, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
    }
    
    func replacePlayerPlaylist(with tracks: [Track]) {
        guard tracks.isEmpty == false else { return }
        
        self.player?.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
        
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
    
    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        self.delegate?.reloadUI()
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
