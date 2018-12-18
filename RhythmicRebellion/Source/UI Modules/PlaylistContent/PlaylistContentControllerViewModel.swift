//
//  PlaylistContentControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import Alamofire

final class PlaylistContentControllerViewModel: PlaylistContentViewModel {
    // MARK: - Private properties -

    private(set) weak var delegate: PlaylistContentViewModelDelegate?
    private(set) weak var router: PlaylistContentRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) weak var restApiService: RestApiService?
    private(set) weak var audioFileLocalStorageService: AudioFileLocalStorageService?
    private(set) var textImageGenerator: TextImageGenerator
    private(set) var trackPriceFormatter: MoneyFormatter

    private var playlist: Playlist
    private var playlistItems: [Track]?

    private var lockedPlaylistItemsIds: Set<Int>

    var isPlaylistEmpty: Bool { return self.playlistItems?.isEmpty ?? false }
    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist, isEmpty: self.isPlaylistEmpty) }

    // MARK: - Lifecycle -

    deinit {
        self.application?.removeWatcher(self)
        self.player?.removeWatcher(self)
        self.audioFileLocalStorageService?.removeWatcher(self)
    }

    init(router: PlaylistContentRouter, application: Application, player: Player, restApiService: RestApiService, audioFileLocalStorageService: AudioFileLocalStorageService, playlist: Playlist) {
        self.router = router
        self.application = application
        self.player = player
        
        self.restApiService = restApiService
        self.audioFileLocalStorageService = audioFileLocalStorageService
        
        self.playlist = playlist
        self.textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 7.0))

        self.trackPriceFormatter = MoneyFormatter()
        self.lockedPlaylistItemsIds = Set<Int>()
    }

    func load(with delegate: PlaylistContentViewModelDelegate) {
        self.delegate = delegate

        self.loadItems()

        self.delegate?.reloadUI()
        self.delegate?.reloadPlaylistUI()

        self.application?.addWatcher(self)
        self.player?.addWatcher(self)
        self.audioFileLocalStorageService?.addWatcher(self)
    }

    func loadItems() {
        let processResults: (Result<[Track]>) -> Void = { [weak self] (tracksResult) in
            switch tracksResult {
            case .success(let tracks):
                self?.playlistItems = tracks
                self?.delegate?.reloadUI()
                self?.delegate?.reloadPlaylistUI()
            case .failure(let error):
                self?.delegate?.show(error: error, completion: { [weak self] in self?.delegate?.reloadUI() })
            }
        }
        if self.playlist.isFanPlaylist {
            self.restApiService?.fanTracks(for: self.playlist.id, completion: processResults)
        } else {
            self.restApiService?.tracks(for: self.playlist.id, completion: processResults)
        }
    }

    func reload() {
        self.loadItems()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistItems?.count ?? 0
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count else { return nil }

        let track = playlistItems[indexPath.item]

        return TrackViewModel(track: track,
                              user: self.application?.user,
                              player: self.player,
                              audioFileLocalStorageService: self.audioFileLocalStorageService,
                              textImageGenerator: self.textImageGenerator,
                              isCurrentInPlayer: player?.currentItem?.playlistItem.track.id == track.id,
                              isLockedForActions: self.lockedPlaylistItemsIds.contains(track.id))
    }

    func selectObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems, let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            play(tracks: [playlistItems[indexPath.item]])
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

    // MARK: Action support

    private func play(tracks: [Track]) {
        guard tracks.isEmpty == false else { return }

        self.player?.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard let playlistItem = playlistItems?.first else {
                guard let error = error else { return }
                self?.delegate?.show(error: error)
                return
            }

            self?.player?.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })
        })
    }

    private func addToPlayerPlaylist(tracks: [Track], at position: Player.PlaylistPosition) {
        guard tracks.isEmpty == false else { return }

        self.player?.add(tracks: tracks, at: position, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })
    }

    private func replacePlayerPlaylist(with tracks: [Track]) {
        guard tracks.isEmpty == false else { return }

        self.player?.replace(with: tracks, completion: { [weak self] (playlistItems, error) in
            guard let error = error else { return }
            self?.delegate?.show(error: error)
        })

    }

    private func clear(playlist: Playlist) {
        guard let fanPlaylist = playlist as? FanPlaylist else { return }

        self.restApiService?.fanClear(playlist: fanPlaylist, completion: { [weak self] (error) in
            guard let error = error else {
                self?.playlistItems?.removeAll()
                self?.delegate?.reloadUI()
                self?.delegate?.reloadPlaylistUI()
                return
            }

            self?.delegate?.show(error: error)
        })
    }

    // MARK: - Playlist Actions -
    
    func actionTypes(for playlist: Playlist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        switch playlist {
        case _ as FanPlaylist:
            return [.playNow, .playNext, .playLast, .replaceCurrent, .toPlaylist, .delete]
        case _ as DefinedPlaylist:
            return [.playNow, .playNext, .playLast, .toPlaylist, .replaceCurrent]
        default: return []
        }
    }

    func confirmation(for actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, with playlist: Playlist) -> ConfirmationAlertViewModel.ViewModel? {

        switch actionType {
        case .clear: return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
                                        switch actionConfirmationType {
                                        case .ok: self?.performeAction(with: actionType, for: playlist)
                                        default: break
                                        }
                            })

        case .delete: return ConfirmationAlertViewModel.Factory.makeDeletePlaylistViewModel(actionCallback: { [weak self] (actionConfirmationType) in
                                        switch actionConfirmationType {
                                        case .ok: self?.performeAction(with: actionType, for: playlist)
                                        default: break
                                        }
                            })

        default: return nil
        }
    }

    func performeAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, for playlist: Playlist) {

        switch actionType {
        case .playNow: self.play(tracks: self.playlistItems ?? [])
        case .playNext: self.addToPlayerPlaylist(tracks: self.playlistItems ?? [], at: .next)
        case .playLast: self.addToPlayerPlaylist(tracks: self.playlistItems ?? [], at: .last)
        case .replaceCurrent: self.replacePlayerPlaylist(with: self.playlistItems ?? [])
        case .toPlaylist: self.router?.showAddToPlaylist(for: playlist)
        case .clear: self.clear(playlist: playlist)

        case .delete:
            guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.isDefault == false else { return }

            self.application?.delete(playlist: fanPlaylist, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })

        case .cancel: break
        }
    }

    func isAction(with actionType: PlaylistActionsViewModels.ActionViewModel.ActionType, availableFor playlist: Playlist) -> Bool {
        switch actionType {
        case .playNow, .playNext, .playLast, .replaceCurrent: return self.playlistItems?.isEmpty == false
        case .toPlaylist: return self.application?.user?.isGuest == false && self.playlistItems?.isEmpty == false
        case .delete: return playlist.isFanPlaylist && playlist.isDefault == false
        case .clear: return false
        default: return true
        }
    }

    func filteredActionsTypes(for playlist: Playlist) -> [PlaylistActionsViewModels.ActionViewModel.ActionType] {
        return self.actionTypes(for: playlist).filter {
            self.isAction(with: $0, availableFor: self.playlist)
        }
    }

    func playlistActions() -> PlaylistActionsViewModels.ViewModel? {

        let filteredPlaylistActionsTypes = self.filteredActionsTypes(for: playlist)

        let playlistActions = PlaylistActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredPlaylistActionsTypes) { [weak self] (actionType) in
            guard let `self` = self else { return }
            guard let confirmationViewModel = self.confirmation(for: actionType, with: self.playlist) else {
                self.performeAction(with: actionType, for: self.playlist)
                return
            }

            self.delegate?.showConfirmation(confirmationViewModel: confirmationViewModel)
        }

        let title = filteredPlaylistActionsTypes.isEmpty ? playlist.name : nil
        let message = filteredPlaylistActionsTypes.isEmpty ? NSLocalizedString("No actions available", comment: "Empty playlist actions message") : nil

        return PlaylistActionsViewModels.ViewModel(title: title,
                                                   message: message,
                                                   actions: playlistActions)
    }

    func clearPlaylist() {
        guard let confirmationViewModel = self.confirmation(for: .clear, with: self.playlist) else {
            self.performeAction(with: .clear, for: self.playlist)
            return
        }

        self.delegate?.showConfirmation(confirmationViewModel: confirmationViewModel)
    }
    
    // MARK: - Track Actions -

    func isAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, availableFor track: Track) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track) && !fanUser.profile.forceToPlay.contains(track.id)
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(track) && fanUser.profile.forceToPlay.contains(track.id)
        case .playNow, .playLast, .playNext: return track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .delete: return self.playlist.isFanPlaylist
        case .replaceCurrent: return false
        case .addToCart(_):
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.hasPurchase(for: track) == false
        default: return true
        }
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: Track) {

        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(trackId: track.id, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(trackId: track.id, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow: self.play(tracks: [track])
        case .playNext: self.addToPlayerPlaylist(tracks: [track], at: .next)
        case .playLast: self.addToPlayerPlaylist(tracks: [track], at: .last)
        case .toPlaylist: self.router?.showAddToPlaylist(for: [track])
        case .delete:
            guard let fanPlaylist = self.playlist as? FanPlaylist else { return }

            self.lockedPlaylistItemsIds.insert(track.id)
            if let index = self.playlistItems?.index(of: track) {
                self.delegate?.reloadObjects(at: [IndexPath(item: index, section: 0)])
            }

            self.restApiService?.fanDelete(track, from: fanPlaylist, completion: { [weak self] (error) in

                self?.lockedPlaylistItemsIds.remove(track.id)

                if let error = error {
                    self?.delegate?.show(error: error)
                    if let index = self?.playlistItems?.index(of: track) {
                        self?.delegate?.reloadObjects(at: [IndexPath(item: index, section: 0)])
                    }
                } else {
                    if let index = self?.playlistItems?.index(of: track) {
                        self?.playlistItems?.remove(at: index)
                        self?.delegate?.reloadUI()
                        if self?.isPlaylistEmpty ?? false {
                            self?.delegate?.reloadPlaylistUI()
                        }
                    }
                }
            })
        default: break
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel? {
        guard let playlistItems = self.playlistItems, indexPath.row < playlistItems.count else { return nil }
        let track = playlistItems[indexPath.row]

        var trackActionsTypes = TrackActionsViewModels.allActionsTypes
        if  let trackPrice = track.price,
            let trackPriceString = self.trackPriceFormatter.string(from: trackPrice) {
            trackActionsTypes.append(.addToCart(trackPriceString))
        }

        let filteredTrackActionsTypes = trackActionsTypes.filter {
            return self.isAction(with: $0, availableFor: track)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = TrackActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, track] (actionType) in
            self?.performeAction(with: actionType, for: track)
        }

        return TrackActionsViewModels.ViewModel(title: nil,
                                                message: nil,
                                                actions: trackActions)
    }

    func downloadObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].audioFile else { return }

        self.audioFileLocalStorageService?.download(trackAudioFile: trackAudioFile)
    }

    func cancelDownloadingObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].audioFile else { return }

        self.audioFileLocalStorageService?.cancelDownloading(for: trackAudioFile)
    }

    func objectLoaclURL(at indexPath: IndexPath) -> URL? {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].audioFile,
            let state = self.audioFileLocalStorageService?.state(for: trackAudioFile) else { return nil }

        switch state {
        case .downloaded(let localURL): return localURL
        default: return nil
        }
    }
}

extension PlaylistContentControllerViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeFanPlaylist fanPlaylistState: FanPlaylistState) {
        guard let fanPlaylist = self.playlist as? FanPlaylist, fanPlaylist.id == fanPlaylistState.id else { return }
        guard let updatedFanPlaylist = fanPlaylistState.playlist else { self.router?.dismiss(); return }
        self.playlist = updatedFanPlaylist
        self.delegate?.reloadPlaylistUI()
    }

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
            guard track.artist.id == artistFollowingState.artistId else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) {
        guard let playlistItems = self.playlistItems else { return }

        var changedPurchasedTracksIds = Array(added)
        changedPurchasedTracksIds.append(contentsOf: removed)

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
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

extension PlaylistContentControllerViewModel: PlayerObserver {
    
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
        guard let playlistItems = self.playlistItems else { return }
        guard let playerCurrentTrack = self.player?.currentItem?.playlistItem.track else { return }

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
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

extension PlaylistContentControllerViewModel: AudioFileLocalStorageServiceObserver {

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, track) in playlistItems.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}
