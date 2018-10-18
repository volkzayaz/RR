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

    private var playlist: PlaylistShortInfo
    private var playlistTracks: [Track] = [Track]()

    var playlistHeaderViewModel: PlaylistHeaderViewModel { return PlaylistHeaderViewModel(playlist: self.playlist) }

    // MARK: - Lifecycle -

    init(router: PlaylistContentRouter, application: Application, player: Player, restApiService: RestApiService, audioFileLocalStorageService: AudioFileLocalStorageService, playlist: PlaylistShortInfo) {
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
                              textImageGenerator: self.textImageGenerator)
    }
    
    func selectObject(at indexPath: IndexPath) {
        guard let viewModel = object(at: indexPath), viewModel.isPlayable else { return }

        if !viewModel.isCurrentInPlayer {
            play(track: self.playlistTracks[indexPath.item])
        } else {
            if viewModel.isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
        }
    }

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
    
    private func play(track: Track) {
        self.player?.add(track: track, at: .next, completion: { [weak self] (playerTrack, error) in
            guard error == nil, let trackToPlay = playerTrack else { return }
            self?.player?.performAction(.playNow, for: trackToPlay, completion: nil)
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
        case .playNow:
            self.play(track: track)
        case .playNext: self.player?.add(track: track, at: .next, completion: nil)
        case .playLast: self.player?.add(track: track, at: .last, completion: nil)
        case .toPlaylist:
            self.router?.showAddToPlaylist(for: track)
        case .delete:
            self.restApiService?.fanDelete(track, from: self.playlist, completion: { (error) in
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

extension PlaylistContentControllerViewModel: PlayerObserver {
    
    func player(player: Player, didChangeStatus status: PlayerStatus) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayState isPlaying: Bool) {
        self.delegate?.reloadUI()
    }
    
    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.delegate?.reloadUI()
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
