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
    private var playlistTracks: [Track] = [Track]()

    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist) }

    // MARK: - Lifecycle -

    deinit {
        self.application?.removeObserver(self)
        self.player?.removeObserver(self)
        self.audioFileLocalStorageService?.removeObserver(self)
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
    }

    func load(with delegate: PlaylistContentViewModelDelegate) {
        self.delegate = delegate

        self.loadTracks()

        self.delegate?.reloadUI()
        self.delegate?.reloadPlaylistUI()

        self.application?.addObserver(self)
        self.player?.addObserver(self)
        self.audioFileLocalStorageService?.addObserver(self)
    }

    func loadTracks() {
        let processResults: (Result<[Track]>) -> Void = { [weak self] (tracksResult) in
            switch tracksResult {
            case .success(let tracks):
                self?.playlistTracks = tracks
                self?.delegate?.reloadUI()
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
        self.loadTracks()
    }

    func numberOfItems(in section: Int) -> Int {
        return self.playlistTracks.count
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard indexPath.item < self.playlistTracks.count else { return nil }

        let track = self.playlistTracks[indexPath.item]

        return TrackViewModel(track: track,
                              user: self.application?.user,
                              player: self.player,
                              audioFileLocalStorageService: self.audioFileLocalStorageService,
                              textImageGenerator: self.textImageGenerator,
                              isCurrentInPlayer: player?.currentItem?.playlistItem.track.id == track.id)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            play(tracks: [self.playlistTracks[indexPath.item]])
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
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
        case .playNow: self.play(tracks: self.playlistTracks)
        case .playNext: self.player?.add(tracks: self.playlistTracks, at: .next, completion: nil)
        case .playLast: self.player?.add(tracks: self.playlistTracks, at: .last, completion: nil)
        case .toPlaylist: self.router?.showAddToPlaylist(for: playlist)
        case .replaceCurrent: self.player?.replace(with: self.playlistTracks, completion: nil)
        case .clear:
            guard let fanPlaylist = self.playlist as? FanPlaylist else { return }

            self.restApiService?.fanClear(playlist: fanPlaylist, completion: { [weak self] (error) in
                guard let error = error else {
                    self?.playlistTracks.removeAll()
                    self?.delegate?.reloadUI()
                    return
                }

                self?.delegate?.show(error: error)
            })

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
        case .playNow, .playNext, .playLast, .replaceCurrent: return true
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .delete: return playlist.isFanPlaylist && playlist.isDefault == false
        case .clear: return false
        default: return true
        }
    }

    func playlistActions() -> PlaylistActionsViewModels.ViewModel? {

        let filteredPlaylistActionsTypes = self.actionTypes(for: self.playlist).filter {
            return self.isAction(with: $0, availableFor: self.playlist)
        }

        guard filteredPlaylistActionsTypes.count > 0 else { return nil }

        let playlistActions = PlaylistActionsViewModels.Factory().makeActionsViewModels(actionTypes: filteredPlaylistActionsTypes) { [weak self] (actionType) in
            guard let `self` = self else { return }
            guard let confirmationViewModel = self.confirmation(for: actionType, with: self.playlist) else {
                self.performeAction(with: actionType, for: self.playlist)
                return
            }

            self.delegate?.showConfirmation(confirmationViewModel: confirmationViewModel)
        }

        return PlaylistActionsViewModels.ViewModel(title: nil,
                                                   message: nil,
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
    
    private func play(tracks: [Track]) {
        self.player?.add(tracks: tracks, at: .next, completion: { [weak self] (playlistItems, error) in
            guard error == nil, let playlistItem = playlistItems?.first else { return }
            self?.player?.performAction(.playNow, for: playlistItem, completion: nil)
        })
    }

    func performeAction(with actionType: TrackActionsViewModels.ActionViewModel.ActionType, for track: Track) {

        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(track: track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(track: track, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow: self.play(tracks: [track])
        case .playNext: self.player?.add(tracks: [track], at: .next, completion: nil)
        case .playLast: self.player?.add(tracks: [track], at: .last, completion: nil)
        case .toPlaylist: self.router?.showAddToPlaylist(for: [track])
        case .delete:
            guard let fanPlaylist = self.playlist as? FanPlaylist else { return }

            self.restApiService?.fanDelete(track, from: fanPlaylist, completion: { (error) in
                if let error = error {
                    self.delegate?.show(error: error)
                } else {
                    if let index = self.playlistTracks.index(of: track) {
                        self.playlistTracks.remove(at: index)
                        self.delegate?.reloadUI()
                    }
                }
            })
        default: break
        }
    }

    func actions(forObjectAt indexPath: IndexPath) -> TrackActionsViewModels.ViewModel? {
        guard indexPath.row < playlistTracks.count else { return nil }
        let track = playlistTracks[indexPath.row]

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
        guard indexPath.item < self.playlistTracks.count, let trackAudioFile = self.playlistTracks[indexPath.item].audioFile else { return }

        self.audioFileLocalStorageService?.download(trackAudioFile: trackAudioFile)
    }

    func cancelDownloadingObject(at indexPath: IndexPath) {
        guard indexPath.item < self.playlistTracks.count, let trackAudioFile = self.playlistTracks[indexPath.item].audioFile else { return }

        self.audioFileLocalStorageService?.cancelDownloading(for: trackAudioFile)
    }

    func objectLoaclURL(at indexPath: IndexPath) -> URL? {
        guard indexPath.item < self.playlistTracks.count, let trackAudioFile = self.playlistTracks[indexPath.item].audioFile,
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

        var indexPaths: [IndexPath] = []

        for (index, track) in self.playlistTracks.enumerated() {
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

        for (index, track) in self.playlistTracks.enumerated() {
            guard changedPurchasedTracksIds.contains(track.id) else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}

extension PlaylistContentControllerViewModel: PlayerObserver {
    
    func player(player: Player, didChangeStatus status: PlayerStatus) {
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

        for (index, track) in self.playlistTracks.enumerated() {
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

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFile: TrackAudioFile) {

        var indexPaths: [IndexPath] = []

        for (index, track) in self.playlistTracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFile: TrackAudioFile) {

        var indexPaths: [IndexPath] = []

        for (index, track) in self.playlistTracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFile: TrackAudioFile) {
        var indexPaths: [IndexPath] = []

        for (index, track) in self.playlistTracks.enumerated() {
            guard let audioFile = track.audioFile, audioFile.id == trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}
