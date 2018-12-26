//
//  PlayerNowPlayingControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/6/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol PlayerNowPlayingViewModelDelegate: class, ErrorPresenting {
    
    func reloadUI()
    func reloadPlaylistUI()
    
    func reloadObjects(at indexPath: [IndexPath])
}

final class NowPlayingViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerNowPlayingViewModelDelegate?
    private(set) weak var router: PlayerNowPlayingRouter?
    private(set) weak var application: Application?
    private(set) weak var player: Player?
    private(set) weak var audioFileLocalStorageService: AudioFileLocalStorageService?

    private(set) var textImageGenerator: TextImageGenerator
    private(set) var trackPriceFormatter: MoneyFormatter

    private var playlistItems: [PlayerPlaylistItem]?

    var isPlaylistEmpty: Bool { return self.playlistItems?.isEmpty ?? false }

    // MARK: - Lifecycle -

    deinit {
        self.application?.removeWatcher(self)
        self.player?.removeWatcher(self)
        self.audioFileLocalStorageService?.removeWatcher(self)
    }

    init(router: PlayerNowPlayingRouter,
         application: Application,
         player: Player,
         audioFileLocalStorageService: AudioFileLocalStorageService) {
        self.router = router
        self.application = application
        self.player = player
        self.audioFileLocalStorageService = audioFileLocalStorageService
        self.textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
        self.trackPriceFormatter = MoneyFormatter()
    }

}



extension NowPlayingViewModel {
    
    func load(with delegate: PlayerNowPlayingViewModelDelegate) {
        self.delegate = delegate

        self.loadItems()
        self.application?.addWatcher(self)
        self.player?.addWatcher(self)
        self.audioFileLocalStorageService?.addWatcher(self)
    }

    func loadItems() {
        self.playlistItems = self.player?.playlistItems ?? []

        self.delegate?.reloadUI()
        self.delegate?.reloadPlaylistUI()
    }

}



/////////////////
/////////////////
/////---------DataSource
/////////////////
/////////////////




extension NowPlayingViewModel {

    func numberOfItems(in section: Int) -> Int {
        return self.playlistItems?.count ?? 0
    }

    func object(at indexPath: IndexPath) -> TrackViewModel? {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count else { return nil }
                
        let playlistItem = playlistItems[indexPath.item]

        return TrackViewModel(track: playlistItem.track,
                              user: application?.user,
                              player: player,
                              audioFileLocalStorageService: audioFileLocalStorageService,
                              textImageGenerator: textImageGenerator,
                              isCurrentInPlayer: player?.currentItem?.playlistItem == playlistItem,
                              isLockedForActions: false)
    }

    func selectObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems,
              let viewModel = object(at: indexPath),
              viewModel.isPlayable else {
                return
        }
        
        if !viewModel.isCurrentInPlayer {
            self.player?.performAction(.playNow,
                                       for: playlistItems[indexPath.item],
                                       completion: { [weak self] (error) in
                                        guard let error = error else { return }
                                        self?.delegate?.show(error: error)
                                       })
            return
        }
        
        if viewModel.isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        
    }

}

extension NowPlayingViewModel {
    // MARK: - Track Actions -

    func isAction(with actionType: ActionViewModel.ActionType,
                  availableFor playlistItem: PlayerPlaylistItem) -> Bool {
        switch actionType {
        case .forceToPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) &&
                  !fanUser.profile.forceToPlay.contains(playlistItem.track.id)
            
        case .doNotPlay:
            guard let fanUser = self.application?.user as? FanUser else { return false }
            return fanUser.isCensorshipTrack(playlistItem.track) &&
                   fanUser.profile.forceToPlay.contains(playlistItem.track.id)
            
        case .playNow: return playlistItem.track.isPlayable
        case .toPlaylist: return self.application?.user?.isGuest == false
        case .replaceCurrent, .playNext, .playLast: return false
        case .delete: return true
        case .addToCart(_):
            guard let fanUser = self.application?.user as? FanUser else { return false}
            return fanUser.hasPurchase(for: playlistItem.track) == false
        default: return true
        }
    }

    func performeAction(with actionType: ActionViewModel.ActionType,
                        for playlistItem: PlayerPlaylistItem) {
        switch actionType {
        case .forceToPlay:
            self.application?.allowPlayTrackWithExplicitMaterial(trackId: playlistItem.track.id, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .doNotPlay:
            self.application?.disallowPlayTrackWithExplicitMaterial(trackId: playlistItem.track.id, completion: { (allowTrackResult) in
                switch allowTrackResult {
                case .failure(let error): self.delegate?.show(error: error)
                default: break
                }
            })
        case .playNow:
            self.player?.performAction(.playNow, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })

        case .delete:
            self.player?.performAction(.delete, for: playlistItem, completion: { [weak self] (error) in
                guard let error = error else { return }
                self?.delegate?.show(error: error)
            })
        case .toPlaylist: self.router?.showAddToPlaylist(for: [playlistItem.track])
        default: break
        }
    }

    func confirmation(for action : PlayerNowPlayingTableHeaderView.Actions) -> ConfirmationAlertViewModel.ViewModel? {

        switch action {
        case .clear:
            return ConfirmationAlertViewModel.Factory.makeClearPlaylistViewModel(actionCallback: { [weak self] (actionType) in
                switch actionType {
                case .ok: self?.player?.clearPlaylist()
                default: break
                }
            })
        default: return nil
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

    func actions(forObjectAt indexPath: IndexPath) -> AlertActionsViewModel<ActionViewModel>? {
        guard let playlistItems = self.playlistItems, indexPath.row < playlistItems.count else { return nil }
        let playlistItem = playlistItems[indexPath.row]

        var trackActionsTypes = ActionViewModel.allTypes
        if  let trackPrice = playlistItem.track.price,
            let trackPriceString = self.trackPriceFormatter.string(from: trackPrice) {
            trackActionsTypes.append(.addToCart(trackPriceString))
        }

        let filteredTrackActionsTypes = trackActionsTypes.filter {
            return self.isAction(with: $0, availableFor: playlistItem)
        }

        guard filteredTrackActionsTypes.count > 0 else { return nil }

        let trackActions = Factory().makeActionsViewModels(actionTypes: filteredTrackActionsTypes) { [weak self, playlistItem] (actionType) in
            self?.performeAction(with: actionType, for: playlistItem)
        }

        return AlertActionsViewModel<ActionViewModel>(title: nil,
                                                message: nil,
                                                actions: trackActions)

    }
    
}



/////////////////
/////////////////
/////---------Downloading audio
/////////////////
/////////////////




extension NowPlayingViewModel {

    func downloadObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].track.audioFile else { return }

        self.audioFileLocalStorageService?.download(trackAudioFile: trackAudioFile)
    }

    func cancelDownloadingObject(at indexPath: IndexPath) {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].track.audioFile else { return }

        self.audioFileLocalStorageService?.cancelDownloading(for: trackAudioFile)
    }

    func objectLoaclURL(at indexPath: IndexPath) -> URL? {
        guard let playlistItems = self.playlistItems, indexPath.item < playlistItems.count,
            let trackAudioFile = playlistItems[indexPath.item].track.audioFile,
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





extension NowPlayingViewModel: ApplicationObserver {

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in playlistItems.enumerated() {
            guard playlistItem.track.artist.id == artistFollowingState.artistId else { continue }
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

        for (index, playlistItem) in playlistItems.enumerated() {
            guard changedPurchasedTracksIds.contains(playlistItem.track.id) else { continue }
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





extension NowPlayingViewModel: PlayerObserver {
    
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
        guard let playlistItems = self.playlistItems else { return }
        guard let playerCurrentTrack = self.player?.currentItem?.playlistItem.track else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in playlistItems.enumerated() {
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



/////////////////
/////////////////
/////---------Audio downloading and sharing
/////////////////
/////////////////





extension NowPlayingViewModel: AudioFileLocalStorageServiceObserver {

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didStartDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didFinishDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }

    func audioFileLocalStorageService(_ audioFileLocalStorageService: AudioFileLocalStorageService, didCancelDownload trackAudioFileLocalItem: TrackAudioFileLocalItem) {

        guard let playlistItems = self.playlistItems else { return }

        var indexPaths: [IndexPath] = []

        for (index, playlistItem) in playlistItems.enumerated() {
            guard let audioFile = playlistItem.track.audioFile, audioFile.id == trackAudioFileLocalItem.trackAudioFile.id else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        if indexPaths.isEmpty == false {
            self.delegate?.reloadObjects(at: indexPaths)
        }
    }
}
