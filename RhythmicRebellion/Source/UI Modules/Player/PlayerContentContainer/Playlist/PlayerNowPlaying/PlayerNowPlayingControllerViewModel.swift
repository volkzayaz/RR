//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class PlayerNowPlayingControllerViewModel: PlayerNowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerNowPlayingViewModelDelegate?
    private(set) weak var router: PlayerNowPlayingRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) weak var audioFileLocalStorageService: AudioFileLocalStorageService?

    private(set) var textImageGenerator: TextImageGenerator
    private(set) var trackPriceFormatter: MoneyFormatter

    private var playlistItems: [PlayerPlaylistItem] = [PlayerPlaylistItem]()

    // MARK: - Lifecycle -

    deinit {
        self.application?.removeObserver(self)
        self.player?.removeObserver(self)
        self.audioFileLocalStorageService?.removeObserver(self)
    }

    init(router: PlayerNowPlayingRouter, application: Application, player: Player, audioFileLocalStorageService: AudioFileLocalStorageService) {
        self.router = router
        self.application = application
        self.player = player
        self.audioFileLocalStorageService = audioFileLocalStorageService
        self.textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
        self.trackPriceFormatter = MoneyFormatter()
    }

    func load(with delegate: PlayerNowPlayingViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()
        self.application?.addObserver(self)
        self.player?.addObserver(self)
        self.audioFileLocalStorageService?.addObserver(self)
    }

    func loadTracks() {
        self.playlistItems = self.player?.playlistItems ?? []
        self.delegate?.reloadUI()
    }

    func reload() {
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistItems.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.playlistItems.count else { return nil }
                
        let playlistItem = self.playlistItems[indexPath.item]

        return TrackViewModel(track: playlistItem.track,
                              user: self.application?.user,
                              player: self.player,
                              audioFileLocalStorageService: self.audioFileLocalStorageService,
                              textImageGenerator: self.textImageGenerator,
                              isCurrentInPlayer: self.player?.currentItem?.playlistItem == playlistItem)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            self.player?.performAction(.playNow, for: self.playlistItems[indexPath.item], completion: nil)
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor playlistItem: PlayerPlaylistItem) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) && !fanUser.profile.forceToPlay.contains(playlistItem.track.id)
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) && fanUser.profile.forceToPlay.contains(playlistItem.track.id)
        case .playNow: return playlistItem.track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        case .delete: return self.playlistItems.count > 1
        case .addToCart(_):
            guard let fanUser = self.application?.user as? FanUser else { return false}
            return fanUser.hasPurchase(for: playlistItem.track) == false
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for playlistItem: PlayerPlaylistItem) {
        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(track: playlistItem.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(track: playlistItem.track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow: self.player?.performAction(.playNow, for: playlistItem, completion: nil)
        case .delete: self.player?.performAction(.delete, for: playlistItem, completion: nil)
        case .toPlaylist:
            self.router?.showAddToPlaylist(for: playlistItem.track)
            break
        default: break
        }
    }
    
    func perform(action : PlayerNowPlayingTableHeaderView.Actions) {
        switch action {
        case .clear:
            self.player?.clearPlaylist()
        default:
            break
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel? {
        guard indexPath.row < self.playlistItems.count else { return nil }
        let playlistItem = self.playlistItems[indexPath.row]

        var trackActionsTypes = TrackActionsViewModels.allActionsTypes
        if  let trackPrice = playlistItem.track.price,
            let trackPriceString = self.trackPriceFormatter.string(from: trackPrice) {
            trackActionsTypes.append(.addToCart(trackPriceString))
        }

        let filteredTrackActionsTypes = trackActionsTypes.filter {
            return self.isAction(with: $0, availableFor: playlistItem)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = TrackActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, playlistItem] (actionType) in
            self?.performeAction(with: actionType, for: playlistItem)
        }

        return TrackActionsViewModels.ViewModel(title: nil,
                                                message: nil,
                                                actions: trackActions)

    }

    func downloadObject(at indexPath: IndexPath) {
        guard indexPath.item < self.playlistItems.count, let trackAudioFile = self.playlistItems[indexPath.item].track.audioFile else { return }

        self.audioFileLocalStorageService?.download(trackAudioFile: trackAudioFile)
    }

    func cancelDownloadingObject(at indexPath: IndexPath) {
        guard indexPath.item < self.playlistItems.count, let trackAudioFile = self.playlistItems[indexPath.item].track.audioFile else { return }

        self.audioFileLocalStorageService?.cancelDownloading(for: trackAudioFile)
    }

    func objectLoaclURL(at indexPath: IndexPath) -> URL? {
        guard indexPath.item < self.playlistItems.count, let trackAudioFile = self.playlistItems[indexPath.item].track.audioFile,
            let state = self.audioFileLocalStorageService?.state(for: trackAudioFile) else { return nil }

        switch state {
        case .downloaded(let localURL): return localURL
        default: return nil
        }
    }
}

extension PlayerNowPlayingControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChange followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard playlistItem.track.artist.id == artistFollowingState.artistId else { continue }
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

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard changedPurchasedTracksIds.contains(playlistItem.track.id) else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

}

extension PlayerNowPlayingControllerViewModel: PlayerObserver {
    
    func playerDidChangePlaylist(player: Player) {
        self.reload()
    }
    
    func player(player: Player, didChangeStatus status: PlayerStatus) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.delegate?.reloadUI()
    }


    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval) {
        guard let playerCurrentTrack = self.player?.currentItem?.playlistItem.track else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard playlistItem.track.id == playerCurrentTrack.id else { continue }
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

extension PlayerNowPlayingControllerViewModel: AudioFileLocalStorageServiceObserver {

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFile: TrackAudioFile) {

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFile: TrackAudioFile) {

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFile: TrackAudioFile) {
        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in self.playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}
