//
//  Player.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

import RxSwift
import RxCocoa

//import os.log

private var playerKVOContext = 0

public enum PlayerStatus : Int {

    case unknown
    case initialized
    case failed
}

public enum AudioFileType: UInt {
    case original
    case backing
    case clean
}

public enum PlayerInitializationAction : Int {

    case none
    case playCurrent
    case pause
    case playForward
    case playBackward
}

protocol PlayerWatcher: class {

    func player(player: Player, didChangeBlockedState isBlocked: Bool)

    func player(player: Player, didChange status: PlayerStatus)

    func player(player: Player, didChangePlayState isPlaying: Bool)

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?)

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem)
    func player(player: Player, didChangePlayerItemCurrentTime time: TimeInterval)
    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval)

    func player(player: Player, didUpdateTracksTotalPlayMSeconds tracksTotalPlayMSeconds: [Int : UInt64])

    func playerDidChangePlaylist(player: Player)
}

extension PlayerWatcher {

    func player(player: Player, didChangeBlockedState isBlocked: Bool) { }

    func player(player: Player, didChange status: PlayerStatus) { }

    func player(player: Player, didChangePlayState isPlaying: Bool) { }

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) { }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) { }
    func player(player: Player, didChangePlayerItemCurrentTime time: TimeInterval) { }
    func player(player: Player, didChangePlayerItemTotalPlayTime time: TimeInterval) { }

    func player(player: Player, didUpdateTracksTotalPlayMSeconds tracksTotalPlayMSeconds: [Int : UInt64]) { }
    
    func playerDidChangePlaylist(player: Player) {}
}

class Player: NSObject, Watchable {

    enum KaraokeMode {
        case none
        case lyrics
        case karaoke
    }

    enum PlaylistPosition {
        case next
        case last
    }

    enum Actions {
        case playNow
        case setCurrent
        case delete
    }

    
    var daPlaylist = DaPlaylist()
    
    
    typealias WatchType = PlayerWatcher

    let watchersContainer = WatchersContainer<PlayerWatcher>()

    var canForward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized && self.playlist.hasPlaylisItems }

        switch currentQueueItem.content {
        case .addon(let addon): return addon.type == .artistBIO || addon.type == .songCommentary
        default: break
        }

        return self.state.initialized
    }

    var canBackward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized && self.playlist.hasPlaylisItems}

        switch currentQueueItem.content {
        case .addon(let addon): return addon.type == .artistBIO || addon.type == .songCommentary
        case .track(_), .stub(_):
            guard let trackProgress = self.currentTrackState?.progress, trackProgress > 0.3 else { return self.state.initialized }
            return true
        }
    }

    var canSeek: Bool {
        guard self.state.initialized, let currentQueueItem = self.playerQueue.currentItem else { return false }

        switch currentQueueItem.content {
        case .addon(_), .stub(_): return false
        case .track(_): return self.state.waitingAddons == false
        }
    }

    var currentItem: PlayerItem? {
        return self.playerQueue.playerItem
    }

    var currentItemObservable: BehaviorRelay<PlayerItem?> {
        return self.playerQueue.playerItemObservable
    }

    var currentQueueItem: PlayerQueueItem? {
        return self.playerQueue.currentItem
    }

    var currentItemDuration: TimeInterval? {
        guard let audioFile = self.currentItem?.playlistItem.track.audioFile else { return nil }
        return TimeInterval(audioFile.duration)
    }

    var currentItemTime: TimeInterval? {
        guard self.currentItem != nil else { return nil }
        guard let currentTrackState = self.currentTrackState else { return 0.0 }
        return currentTrackState.progress
    }

    var currentItemRestrictedTime: TimeInterval? {
        guard let currentQueueItem = self.playerQueue.currentItem, self.playerQueue.isReadyToPlay else { return nil }

        switch currentQueueItem.content {
        case .addon(_), .stub(_): return nil
        case .track(_): return self.state.waitingAddons == true ? nil : self.playerQueue.playerItem?.restrictedTime
        }
    }

    private let stateHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    private var isMaster: Bool {
        guard let currentTrackState = self.currentTrackState else { return false }
        return currentTrackState.hash == self.stateHash
    }
    private var isMasterStateSendDate = Date(timeIntervalSinceNow: -2)

    private(set) var config: PlayerConfig?
    private(set) var state: PlayerState = []
    private(set) var initializationAction: PlayerInitializationAction = .none

    private var playBackgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    private var audioSessionIsInterrupted: Bool = false

    @objc private var player = AVQueuePlayer()
    var timeObserverToken: Any?

    var isPlaying: Bool {
        guard self.state.initialized else { return self.state.playing }

        return self.state.playing || self.currentTrackState?.isPlaying ?? false == true }

    var playerCurrentItem: AVPlayerItem? { return self.player.currentItem }
    var playerCurrentItemDuration: TimeInterval? {
        guard let duration = self.playerCurrentItem?.duration, duration.value != 0 else { return nil }
        return TimeInterval(CMTimeGetSeconds(duration)).rounded(.towardZero)
    }

    private let application: Application
    private var webSocketService: WebSocketService { return self.application.webSocketService }

    private let playlist: PlayerPlaylist = PlayerPlaylist()
    private var playerQueue: PlayerQueue = PlayerQueue(preferredAudioFileType: AudioFileType.original)

    public var currentTrackId: TrackId?
    private var currentTrackState: TrackState?

    private var addonsPlayTimer: Timer?

    private var deferredPlaylistItemsPatches = [[String : PlayerPlaylistItemPatch?]]()
    private var defferedTrackId: TrackId?

//    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Player")

    var preferredAudioFileType: AudioFileType { return self.playerQueue.preferredAudioFileType}

    init(with application: Application) {

        self.application = application

        super.init()

        self.application.addWatcher(self)
        self.webSocketService.addWatcher(self)

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(_:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: AVAudioSession.sharedInstance())

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.playback)), mode: AVAudioSession.Mode.default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("an error occurred when audio session category.\n \(error)")
        }

        addObserver(self, forKeyPath: #keyPath(Player.player.rate), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem.status), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem.duration), options: [.new, .initial], context: &playerKVOContext)

        let interval = CMTimeMakeWithSeconds(0.25, preferredTimescale: 4)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = TimeInterval(CMTimeGetSeconds(time))

            self.updateCurrentTrackState(with: timeElapsed)
        }

        self.setupMPRemoteCommands()
    }

    deinit {

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        removeObserver(self, forKeyPath: #keyPath(Player.player.rate), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(Player.player.currentItem), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(Player.player.currentItem.status), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(Player.player.currentItem.duration), context: &playerKVOContext)

        NotificationCenter.default.removeObserver(self)
        self.webSocketService.removeWatcher(self)
    }

    func loadConfig() {
        self.application.restApiService.playerConfig { [weak self] (playerConfigResult) in
            switch playerConfigResult {
            case .success(let playerConfig): self?.config = playerConfig
            default: break
            }
        }
    }

    func performeInitializationAction() {

        var actionCompletion: (() -> ())? = nil
        if self.playBackgroundTaskIdentifier != nil {
            actionCompletion = { [weak self] in
                if let playBackgroundTaskIdentifier = self?.playBackgroundTaskIdentifier {
                    UIApplication.shared.endBackgroundTask(playBackgroundTaskIdentifier)
                    self?.playBackgroundTaskIdentifier = nil
                }
            }
        }

        switch self.initializationAction {
        case .playCurrent: self.play(completion: actionCompletion)
        case .playForward: self.playForward(completion: actionCompletion)
        case .playBackward: self.playBackward(completion: actionCompletion)
        case .pause: self.pause(completion: actionCompletion)
        case .none: break
        }
    }

    func initializePlayer() {

        self.state.initialized = true
        self.audioSessionIsInterrupted = false

        if self.playerQueue.playerItem == nil,
            let lastPlaylistItem = self.playlist.lastPlaylistItem,
            let firstPlayablePlaylistItem = self.findPlayablePlaylistItem(after: lastPlaylistItem) {

            let currentPlayerItem = self.playerItem(for: firstPlayablePlaylistItem)

            self.playerQueue.replace(playerItem: currentPlayerItem, addons: self.currentTrackState != nil ? [] : nil)
            self.replace(playerItems: self.playerQueue.playerItems)
        }

        self.updateMPRemoteInfo()
        if self.initializationAction != .none {
            self.performeInitializationAction()
            self.initializationAction = .none
        }

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = self.canForward
        commandCenter.previousTrackCommand.isEnabled = self.canBackward


        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChange: .initialized)
        })
    }


    func updateCurrentTrackState(with timeElapsed:TimeInterval) {

        var shouldPlayNext = false

        if self.isMaster && self.state.playing == true && self.playerQueue.containsOnlyTrack && self.playerQueue.playerItem?.stubReason == nil {
            let currentTrackState = TrackState(hash: self.stateHash, progress: timeElapsed, isPlaying: self.state.playing)
            self.set(trackState: currentTrackState)
            self.currentTrackState = currentTrackState

            if let restrictedTime = self.playerQueue.playerItem?.restrictedTime, timeElapsed > restrictedTime {
                shouldPlayNext = true
            }
        }

        self.updateMPRemoteInfo()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.previousTrackCommand.isEnabled = self.canBackward
        commandCenter.nextTrackCommand.isEnabled = self.canForward

        if self.playerQueue.containsOnlyTrack && self.playerQueue.playerItem?.stubReason == nil{
            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItemCurrentTime: timeElapsed)
            })
        }

        if shouldPlayNext { self.playForward() }
    }

    func findPlayablePlaylistItem(after playlistItem: PlayerPlaylistItem) -> PlayerPlaylistItem? {

        var currentPlaylistItem = playlistItem
        var trackStubReason: TrackStubReason?
        repeat {
            guard let nextPlaylistItem = self.playlist.nextPlaylistItem(for: currentPlaylistItem, cycled: true),
                nextPlaylistItem != playlistItem else { return playlistItem }
            currentPlaylistItem = nextPlaylistItem
            trackStubReason = self.stubReason(for: nextPlaylistItem.track)
        } while currentPlaylistItem.track.isPlayable == false && (trackStubReason == nil || trackStubReason?.audioFile == nil)

        return currentPlaylistItem
    }

    func findPlayablePlaylistItem(before playlistItem: PlayerPlaylistItem) -> PlayerPlaylistItem? {

        var currentPlaylistItem = playlistItem
        var trackStubReason: TrackStubReason?
        repeat {
            guard let previousPlaylistItem = self.playlist.previousPlaylistItem(for: currentPlaylistItem, cycled: true),
                previousPlaylistItem != playlistItem else { return playlistItem }
            currentPlaylistItem = previousPlaylistItem
            trackStubReason = self.stubReason(for: previousPlaylistItem.track)
        } while currentPlaylistItem.track.isPlayable == false && (trackStubReason == nil || trackStubReason?.audioFile == nil)

        return currentPlaylistItem
    }

    func loadAddons(for track: Track, completion: ((Error?) -> ())?) {

        self.application.restApiService.audioAddons(for: [track.id]) { [weak self] (addonsResult) in

            switch addonsResult {
            case .success(let tracksAddons):
                    self?.playlist.add(tracksAddons: tracksAddons)
                    self?.application.restApiService.artists(with: [track.artist.id], completion: { [weak self] (artistsResult) in

                        switch artistsResult {
                        case .success(let artists):
                            if let addons = artists.first?.addons {
                                self?.playlist.add(tracksAddons: [track.id : addons])
                            }
                            completion?(nil)
                        case .failure(let error):
                            completion?(error)
                        }
                    })

            case .failure(let error):
                completion?(error)
            }

        }
    }

    func prepareAddons(for track: Track, completion: ((Error?) -> ())?) {

        let checkAddonsCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { completion?(error); return }
            guard let currentPlayerItem = self?.currentItem else { return }

            self?.state.waitingAddons = true
            self?.addonsPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                                         repeats: false,
                                                         block: { [weak self] (timer) in
                                                            guard currentPlayerItem.playlistItem == self?.currentItem?.playlistItem else { return }
                                                            self?.apply(addonsIds: [])
//                                                            self?.state.waitingAddons = false
//                                                            self?.playerQueue.replace(addons: [])
//                                                            self?.set(trackBlocked: false)
//                                                            self?.state.playing = true
//                                                            self?.player.play()
            })

            completion?(nil)
        }


        self.state.waitingAddons = false
        self.set(trackBlocked: true) { [weak self] (error) in
            guard error == nil else { completion?(error); return }

            guard let addonsStates = self?.playlist.addonsStates(for: track) else {
                self?.loadAddons(for: track, completion: { [weak self] (error) in
                    guard error == nil else {
                        self?.set(trackBlocked: false)
                        completion?(error)
                        return
                    }

                    guard let addonsStates = self?.playlist.addonsStates(for: track) else {
                        self?.set(trackBlocked: false)
                        completion?(AppError(.prepareAddons))
                        return
                    }


                    self?.checkAddons(trackId: track.id, addonsStates: addonsStates, completion: checkAddonsCompletion)
                })
                return
            }

            self?.checkAddons(trackId: track.id, addonsStates: addonsStates, completion: checkAddonsCompletion)
        }
    }

    func preparePlayerQueueToPlay(completion: ((Error?) -> ())? = nil) {
        guard self.state.initialized, let playerItem = self.playerQueue.playerItem else { completion?(AppError(.notInitialized)); return }

        guard self.playerQueue.isReadyToPlay == true else {
            self.prepareAddons(for: playerItem.playlistItem.track, completion: completion)
            return
        }

        completion?(nil)
    }

    func error() -> Error? {
        guard self.webSocketService.isReachable else { return AppError(.offline) }
        guard self.state.initialized else { return AppError(.notInitialized) }

        return nil
    }

    // MARK: - PlayerItem

    func playerItem(for playlistItem: PlayerPlaylistItem) -> PlayerItem {

        return PlayerItem(playlistItem: playlistItem,
                          stubReason: self.stubReason(for: playlistItem.track),
                          restrictedTime: self.restrictedTime(for: playlistItem.track))
    }

    func restrictedTime(for track: Track) -> TimeInterval? {
        guard track.isFreeForPlaylist == false else { return nil }
        guard let fanUser = self.application.user as? FanUser else { return self.guestRestrictedTime(for: track) }
        guard fanUser.hasPurchase(for: track) == false else { return nil }
        guard (track.isFollowAllowFreeDownload && fanUser.isFollower(for: track.artist.id)) == false else { return nil }

        switch track.previewType {
        case .full:
            guard let previewLimitTimes = track.previewLimitTimes, previewLimitTimes > 0 else { return TimeInterval(45) }
            guard let trackDuration = track.audioFile?.duration else { return TimeInterval(0) }
            guard let trackTotalPlayMSeconds = self.totalPlayMSeconds(for: track.id) else { return nil }

            let trackMaxPlayMSeconds = UInt64(trackDuration * 1000 * previewLimitTimes)
            guard trackMaxPlayMSeconds > trackTotalPlayMSeconds else { return TimeInterval(45) }

            return nil

        case .limit45: return TimeInterval(45)
        case .limit90: return TimeInterval(90)

        default: return nil
        }

    }

    func guestRestrictedTime(for track: Track) -> TimeInterval? {
        switch track.previewType {
        case .full:
            guard let _ = track.previewLimitTimes else { return nil }
            return TimeInterval(45)
        default: return TimeInterval(45)
        }
    }

    func totalPlayMSeconds(for trackId: Int) -> UInt64? {
        return self.playlist.totalPlayMSeconds(for: trackId)
    }

    func stubReason(for track: Track) -> TrackStubReason? {
        guard let _ = track.audioFile else { return .noAudoFile(nil) }
        guard track.previewType != .noPreview else { return .noPreview(self.config?.noPreviewAudioFile) }
        guard let userStubTrackAudioFileReason = self.application.user?.stubTrackAudioFileReason(for: track) else { return nil }

        switch userStubTrackAudioFileReason {
        case .censorship: return .containseExplicitMaterial(self.config?.explicitMaterialAudioFile)
        }
    }

    func shouldSendTrackingTimeRequest(for track: Track) -> Bool {
        guard track.isFreeForPlaylist == false else { return false }
        guard track.previewType == .full, let previewLimitTimes = track.previewLimitTimes, previewLimitTimes > 0 else { return false }

        return self.playlist.totalPlayMSeconds(for: track.id) == nil
    }

    func flipPlayState() {
        isPlaying ? pause() : play()
    }
    
    // MARK: - Actions
    func play(completion: (() -> ())? = nil) {

        self.state.playing = true

        guard self.state.initialized,
                let currentPlayerItem = self.playerQueue.playerItem
                else {
                    self.currentTrackState = TrackState(hash: self.stateHash, progress: self.currentTrackState?.progress ?? 0.0, isPlaying: self.state.playing)
                    self.player.play()
                    completion?()
                    return
        }



        let prepareQueueCompletion: ((Error?) -> ()) = { [weak self] (error) in
            guard error == nil else { self?.player.play(); completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            self?.player.play()
            completion?()
        }

        guard self.currentTrackId == currentPlayerItem.trackId  else {
            let trackState = TrackState(hash: self.stateHash, progress: self.currentTrackState?.progress ?? 0.0, isPlaying: self.state.playing)
            let shouldSendTrackingTimeRequest = self.shouldSendTrackingTimeRequest(for: currentPlayerItem.playlistItem.track)

            self.set(trackId: currentPlayerItem.trackId, trackState: trackState, shouldSendTrackingTimeRequest: shouldSendTrackingTimeRequest) { [weak self] (error) in
                self?.preparePlayerQueueToPlay(completion: { [weak self] (error) in
                    guard error == nil else { prepareQueueCompletion(error); return }
                    guard let `self` = self else { prepareQueueCompletion(nil); return }
                    guard let currentTrackState = self.currentTrackState else { prepareQueueCompletion(nil); return }

                    let time = CMTime(seconds: Double(currentTrackState.progress), preferredTimescale: Int32(kCMTimeMaxTimescale))
                    self.player.currentItem?.seek(to: time, completionHandler: { (success) in
                        prepareQueueCompletion(nil)
                    })
                })
                self?.preparePlayerQueueToPlay(completion: prepareQueueCompletion)
            }
            return
        }

        guard let currentTrackState = self.currentTrackState else {
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: self.state.playing)
            self.set(trackState: trackState) { [weak self] (error) in
                self?.preparePlayerQueueToPlay(completion: prepareQueueCompletion)
            }
            return
        }

        let trackState = TrackState(hash: self.stateHash, progress: currentTrackState.progress, isPlaying: self.state.playing)

        guard self.playerQueue.isReadyToPlay == true || currentTrackState.progress > 1.0 else {
            self.set(trackState: trackState) { [weak self] (error) in
                self?.preparePlayerQueueToPlay(completion: prepareQueueCompletion)
            }
            return
        }

        guard self.playerQueue.containsOnlyTrack == true && self.playerQueue.isReadyToPlay else {
            self.player.play()
            completion?()
            return
        }

        self.set(trackState: trackState) { [weak self] (error) in
            let time = CMTime(seconds: Double(currentTrackState.progress), preferredTimescale: Int32(kCMTimeMaxTimescale))
            self?.player.currentItem?.seek(to: time, completionHandler: { [weak self] (success) in
                guard success == true else { self?.state.playing = false; completion?(); return }
                self?.player.play()
                completion?()
            })
        }
    }

    func pause(completion: (() -> ())? = nil) {

        self.state.playing = false
        self.player.pause()

        guard self.state.initialized, let currentPlayerItem = self.playerQueue.playerItem else {
            completion?()
            return
        }

        let playerCurrentItemCurrentTime = self.currentTrackState?.progress ?? 0.0
        let trackState = TrackState(hash: self.stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
        self.set(trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self else { completion?(); return }

            strongSelf.watchersContainer.invoke({ (observer) in
                observer.player(player: strongSelf, didChangePlayState: trackState.isPlaying)
            })

            completion?()
        }
    }
    
    func clearPlaylist() {

        guard self.state.initialized else { return }

        let trackId = TrackId(id: 0, key: "")
        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: false)
        self.set(trackId: trackId, trackState: trackState, shouldSendTrackingTimeRequest: false) { [weak self] (error) in
            guard let `self` = self, error == nil else { return }

            self.playerQueue.reset()
            self.replace(playerItems: self.playerQueue.playerItems)

            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItem: nil)
            })

            let playlistItemsPatches = [String: PlayerPlaylistItemPatch?]()
            self.updatePlaylist(playlistItemsPatches: playlistItemsPatches, flushing: true, completion: { [weak self] (error) in
                guard let `self` = self, error == nil else { return }

                self.playlist.update(with: playlistItemsPatches)

                self.watchersContainer.invoke({ (observer) in
                    observer.playerDidChangePlaylist(player: self)
                })
            })
        }
    }
    

    func playForward(completion: (() -> ())? = nil) {

        guard self.state.initialized, self.canForward else { completion?(); return }

        guard self.playerQueue.containsOnlyTrack else {
            self.playerQueue.dequeueFirst()

            if self.playerQueue.containsOnlyTrack {
                self.set(trackBlocked: false)
            }

            self.player.advanceToNextItem()
            return
        }

        var nextPlaylistItem: PlayerPlaylistItem? = nil
        if let currentPlaylistItem = self.playerQueue.playerItem?.playlistItem {
            nextPlaylistItem = self.findPlayablePlaylistItem(after: currentPlaylistItem)
        }

        self.setCurrent(playlistItem: nextPlaylistItem, completion: completion)
    }

    func playBackward(completion: (() -> ())? = nil) {

        guard self.canBackward else { completion?(); return }

        let isPlaying = self.isPlaying
        let playerCurrentItemCurrentTime = self.currentItemTime ?? 0.0

        guard playerCurrentItemCurrentTime <= TimeInterval(3.0) else {
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
            self.set(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self else { completion?(); return }

                strongSelf.currentTrackState = trackState
                strongSelf.updateMPRemoteInfo()

                strongSelf.watchersContainer.invoke({ (observer) in
                    observer.player(player: strongSelf, didChangePlayerItemCurrentTime: trackState.progress)
                })

                let time = CMTime(seconds: Double(0.0), preferredTimescale: Int32(kCMTimeMaxTimescale))
                strongSelf.player.currentItem?.seek(to: time, completionHandler: { [weak self] (success) in
                    guard success == true else { completion?(); return }

                    self?.state.playing = isPlaying
                    if isPlaying { self?.player.play() }
                    completion?()
                })
            }
            return
        }

        var previousPlaylistItem: PlayerPlaylistItem? = nil
        if let currentPlaylistItem = self.playerQueue.playerItem?.playlistItem {
            previousPlaylistItem = self.findPlayablePlaylistItem(before: currentPlaylistItem)
        }

        self.setCurrent(playlistItem: previousPlaylistItem, completion: completion)
    }

    func seek(to timeInterval: TimeInterval) {
        guard self.canSeek else { return }

        if let currentPlayerItemRestrictedTime = self.currentItem?.restrictedTime,
            timeInterval > currentPlayerItemRestrictedTime {

            self.playForward()
            return
        }

        let isPlaying = self.isPlaying
        let trackState = TrackState(hash: self.stateHash, progress: timeInterval, isPlaying: isPlaying)
        self.currentTrackState = trackState

        self.state.playing = false

        self.set(trackState: trackState) { [weak self] (error) in
            guard let `self` = self, error == nil else { return }

            let time = CMTime(seconds: Double(timeInterval), preferredTimescale: Int32(kCMTimeMaxTimescale))
            self.player.currentItem?.seek(to: time, completionHandler: { [weak self] (success) in
                self?.state.playing = isPlaying
                if isPlaying { self?.player.play() }

                guard let self = self else { return }
                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayerItemCurrentTime: trackState.progress)
                })
            })
        }
    }

    func setCurrent(playlistItem: PlayerPlaylistItem?, completion: (() -> ())? = nil) {

        self.defferedTrackId = nil

        guard let playlistItem = playlistItem else {
            let trackId = TrackId(id: 0, key: "")
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: false)
            self.set(trackId: trackId, trackState: trackState, shouldSendTrackingTimeRequest: false) { [weak self] (error) in
                guard let `self` = self, error == nil else { return }

                self.player.pause()
                self.playerQueue.reset()
                self.replace(playerItems: self.playerQueue.playerItems)

                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayerItem: nil)
                })
            }
            return
        }

        let currentPlayerItem = self.playerItem(for: playlistItem)
        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: self.isPlaying)
        let shouldSendTrackingTimeRequest = self.shouldSendTrackingTimeRequest(for: currentPlayerItem.playlistItem.track)

        self.set(trackId: currentPlayerItem.trackId, trackState: trackState, shouldSendTrackingTimeRequest: shouldSendTrackingTimeRequest) { [weak self] (error) in
            guard let `self` = self, error == nil else { completion?(); return }

            self.player.pause()
            self.playerQueue.replace(playerItem: currentPlayerItem)
            self.replace(playerItems: self.playerQueue.playerItems)

            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItem: self.currentItem)
            })

            if self.isPlaying {
                self.state.playing = self.isPlaying
                self.preparePlayerQueueToPlay(completion: { [weak self] (error) in
                    guard error == nil else { if self?.state.playing ?? false { self?.player.play() }; completion?(); return }
                    guard self?.state.waitingAddons == false else { completion?(); return }
                    if self?.state.playing ?? false { self?.player.play() }
                    completion?()

                })
            }
        }
    }

    // MARK: - AVPlayer

    func replace(playerItems: [AVPlayerItem]) {
        
        self.player.removeAllItems()
        
        for playerItem in playerItems {
            self.player.insert(playerItem, after: nil)
        }
    }

    // MARK: Notifications
    @objc func audioSessionInterrupted(_ notification: Notification) {
        print("interruption received: \(notification)")

//        os_log("audioSessionInterrupted", log: self.log)


        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {

//            os_log("audioSessionInterrupted type: .began", log: self.log)
            self.audioSessionIsInterrupted = true
            self.state.playingBeforeAudioSessionInterruption = self.state.playing
            if self.state.playing {
                let pauseBackgroundtask = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                self.pause {
    //                os_log("audioSessionInterrupted didPause", log: self.log)
                    UIApplication.shared.endBackgroundTask(pauseBackgroundtask)
                }
            }

        } else if type == .ended {

//            os_log("audioSessionInterrupted type: .ended", log: self.log)

            self.player.pause()
            self.audioSessionIsInterrupted = false
            var options: AVAudioSession.InterruptionOptions = []

            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            }

            if self.webSocketService.state.isConnected == false {

//                os_log("audioSessionInterrupted websocket not connected", log: self.log)

                self.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                if options.contains(.shouldResume) && self.state.playingBeforeAudioSessionInterruption {
                    self.initializationAction = .playCurrent
                }
                if self.webSocketService.state == .disconnected {
//                    os_log("audioSessionInterrupted websocket reconnect", log: self.log)
                    self.webSocketService.reconnect()
                }
            } else {
                if options.contains(.shouldResume) && self.state.playingBeforeAudioSessionInterruption {
//                    os_log("audioSessionInterrupted just play ", log: self.log)
                    self.play()
                }
            }

            self.state.playingBeforeAudioSessionInterruption = false
        }
    }

    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {

        guard self.playerQueue.containsOnlyTrack == false else { self.playForward(); return }

        self.playerQueue.dequeueFirst()

        if self.playerQueue.containsOnlyTrack {
            self.set(trackBlocked: false)
        }

    }

    @objc func audioSessionRouteChange(_ notification: Notification) {

        if let notificationUserInfo = notification.userInfo {
            if let audioSessionRouteChangeReason = AVAudioSession.RouteChangeReason(rawValue: notificationUserInfo[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0) {

                switch audioSessionRouteChangeReason {
                case .oldDeviceUnavailable:
                    if self.state.playing == true { DispatchQueue.main.async { self.player.play() } }
                default: break
                }
            }
        }
    }

    // MARK: KVO Observation

    func observePlayerValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {

        if keyPath == #keyPath(Player.player.rate) {

            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayState: self.player.rate == 1.0)
            })

        } else if keyPath == #keyPath(Player.player.currentItem) {
            guard let currrentQueueItem = self.currentQueueItem else { return }
            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerQueueItem: currrentQueueItem)
            })
        } else if keyPath == #keyPath(Player.player.currentItem.status) {
            switch self.player.currentItem?.status {
            case .readyToPlay?:
                if self.player.rate == 1.0 {
                    if let currentQueueItem = self.playerQueue.currentItem {
                        switch currentQueueItem.content {
                        case .addon(let addon):
                            if let currentItem = self.currentItem {
                                self.playAddon(addon: addon, track: currentItem.playlistItem.track)
                            }
                        default: break
                        }
                    }

                    self.player.play()
                }
            default: break
            }
        } else if keyPath == #keyPath(Player.player.currentItem.duration) {
            guard let currrentQueueItem = self.currentQueueItem else { return }
            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerQueueItem: currrentQueueItem)
            })
        }
    }

    // MARK: - KVO Observation

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        // Update our UI when player or `player.currentItem` changes.
        if context == &playerKVOContext {
            self.observePlayerValue(forKeyPath: keyPath, of: object, change: change)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

extension Player: WebSocketServiceWatcher {

    // MARK: - Apply State

    func apply(currentTrackId: TrackId) {

        guard self.currentTrackId != currentTrackId else { return }

        self.state.playing = false
        self.player.pause()
        self.currentTrackState = nil

        var currentPlayerItem: PlayerItem? = nil
        if let playerPlaylistItem = self.playlist.playListItem(for: currentTrackId) {
            currentPlayerItem = self.playerItem(for: playerPlaylistItem)
            self.defferedTrackId = nil
        } else {
            self.defferedTrackId = currentTrackId
        }

        self.currentTrackId = nil
        self.playerQueue.replace(playerItem: currentPlayerItem)
        self.replace(playerItems: self.playerQueue.playerItems)

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChangePlayerItem: self.currentItem)
        })
    }

    func apply(currentTrackState: TrackState) {


        if self.stateHash != currentTrackState.hash || self.currentTrackState == nil {

            let isPlaying = self.currentTrackState?.isPlaying ?? self.state.playing == true

            self.state.playing = false
            if self.player.timeControlStatus != .paused {
                self.player.pause()
            }

            self.currentTrackState = currentTrackState

            if currentTrackState.progress > 1.0 {
                self.playerQueue.replace(addons: [])
            }

            if isPlaying != currentTrackState.isPlaying {
                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayState: currentTrackState.isPlaying)
                })
            }

            self.watchersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItemCurrentTime: currentTrackState.progress)
            })

        }
    }

    func apply(addonsIds: [Int]) {
        guard self.state.waitingAddons == true,
            let playerItem = self.playerQueue.playerItem,
            let addons = self.playlist.addons(for: playerItem.playlistItem.track, addonsIds: addonsIds) else { return }

        self.playerQueue.replace(playerItem: playerItem, addons: addons)
        self.replace(playerItems: playerQueue.playerItems)
        self.state.waitingAddons = false

        if addons.isEmpty { self.set(trackBlocked: false) }

        if self.state.playing == true { self.player.play() }

        self.addonsPlayTimer?.invalidate()
    }

    func applyDeferredPlaylistItemsPatches() {

        var playlistChanged = false

        while let playlistItemsPatches = self.deferredPlaylistItemsPatches.first {
            let unloadedTracksIds = playlistItemsPatches.compactMap { $0.value?.trackId }.filter { return self.playlist.containsTrack(with: $0) == false }
            guard unloadedTracksIds.isEmpty else { self.getTracks(tracksIds: unloadedTracksIds); break }

            self.playlist.update(with: playlistItemsPatches)

            self.deferredPlaylistItemsPatches.remove(at: 0)
            playlistChanged = true
        }

        if playlistChanged {
            if let defferedTrackId = self.defferedTrackId {
                self.apply(currentTrackId: defferedTrackId)
            }

            self.watchersContainer.invoke({ (observer) in
                observer.playerDidChangePlaylist(player: self)
            })
        }
    }

    //MARK: - Set State
    func set(trackId: TrackId, trackState: TrackState, shouldSendTrackingTimeRequest: Bool, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.setCurrentTrack(trackId: trackId)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard error == nil else { completion?(error); return }

            if shouldSendTrackingTimeRequest {
                let trackingTimeRequestCommand = WebSocketCommand.trackingTimeRequest(for: [trackId.id])
                self?.webSocketService.sendCommand(command: trackingTimeRequestCommand)
            }

            self?.currentTrackId = trackId
            self?.isMasterStateSendDate = Date()
            self?.set(trackState: trackState, completion: completion)
        }
    }

    func set(trackState: TrackState, completion: ((Error?) -> ())? = nil) {

        guard self.state.initialized else { completion?(self.error()); return }


        let webSocketCommand = WebSocketCommand.setTrackState(trackState: trackState)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard error == nil else { print("Set trackstate erorr: \(error)"); completion?(error); return }

            if let strongSelf = self, strongSelf.isMaster == false {
                strongSelf.isMasterStateSendDate = Date()
            }
            self?.currentTrackState = trackState
            completion?(nil)
        }
    }

    func set(trackBlocked: Bool, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.setTrackBlock(isBlocked: trackBlocked)
        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func checkAddons(trackId: Int, addonsStates: [AddonState], completion: ((Error?) -> ())? = nil) {
        let checkAddons = CheckAddons(trackId: trackId, addonsStates: addonsStates)
        let webSocketCommand = WebSocketCommand.checkAddons(checkAddons: checkAddons)

        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func playAddon(addon: Addon, track: Track, completion: ((Error?) -> ())? = nil) {
        let addonState = AddonState(id: addon.id, typeValue: addon.typeValue, trackId: track.id)
        let webSocketCommand = WebSocketCommand.playAddon(addonState: addonState)

        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func loadTracks(tracks: [Track], completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.loadTracks(tracks: tracks)
        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func updatePlaylist(playlistItemsPatches: [String: PlayerPlaylistItemPatch?], flushing: Bool = false, completion: ((Error?) -> ())? = nil) {
        var webSocketCommand = WebSocketCommand.updatePlaylist(playlistItemsPatches: playlistItemsPatches)
        if flushing {
            webSocketCommand.flush = true
        }
        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func getTracks(tracksIds: [Int], completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.getTracks(tracksIds: tracksIds)
        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func trackingTimeRequest(for trackIds: [Int], completion: ((Error?) -> ())? = nil) {
        let trackingTimeRequestCommand = WebSocketCommand.trackingTimeRequest(for: trackIds)
        self.webSocketService.sendCommand(command: trackingTimeRequestCommand, completion: completion)
    }

    //MARK: - WebSocketServiceObserver
    func webSocketServiceDidDisconnect(_ service: WebSocketService) {
        self.state.initialized = false

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = self.canForward
        commandCenter.previousTrackCommand.isEnabled = self.canBackward

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChange: .failed)
        })

        if self.audioSessionIsInterrupted == false && self.webSocketService.isReachable {
            self.webSocketService.reconnect()
        }
    }

    func webSocketServiceDidConnect(_ service: WebSocketService) {
        self.state.initialized = false
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track], flush: Bool) {

        if self.state.initialized && flush == false {
            self.playlist.add(traksToAdd: tracks)
            self.applyDeferredPlaylistItemsPatches()
        } else {
            self.defferedTrackId = nil
            self.deferredPlaylistItemsPatches.removeAll()
            self.playlist.reset(with: [:])
            self.playlist.reset(tracks: tracks)
        }

        let trackIdsForTimeRequest = tracks.filter { self.shouldSendTrackingTimeRequest(for: $0) }.map { $0.id }
        if trackIdsForTimeRequest.isEmpty == false {
            let trackingTimeRequestCommand = WebSocketCommand.trackingTimeRequest(for: trackIdsForTimeRequest)
            self.webSocketService.sendCommand(command: trackingTimeRequestCommand)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceivePlaylistUpdate playlistItemsPatches: [String: PlayerPlaylistItemPatch?], flush: Bool) {

        let tracks = daPlaylist.orderedTracks
        
        daPlaylist.apply(patch: playlistItemsPatches.nullableReduxView)
        
        let tracks2 = daPlaylist.orderedTracks
        
        if self.state.initialized && flush == false {
            guard self.deferredPlaylistItemsPatches.isEmpty else {
                self.deferredPlaylistItemsPatches.append(playlistItemsPatches)
                return
            }

            self.deferredPlaylistItemsPatches.append(playlistItemsPatches)
            self.applyDeferredPlaylistItemsPatches()

        } else {
            self.defferedTrackId = nil
            self.deferredPlaylistItemsPatches.removeAll()
            self.playlist.reset(with: [:])

            self.watchersContainer.invoke({ (observer) in
                observer.playerDidChangePlaylist(player: self)
            })

            self.deferredPlaylistItemsPatches.append(playlistItemsPatches)
            self.applyDeferredPlaylistItemsPatches()
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {

//        print("webSocketService didReceiveCurrentTrackId trackId: \(trackId)")

        if self.state.initialized {
            guard let trackId = trackId else { return }
            self.apply(currentTrackId: trackId)
        } else {
            guard let trackId = trackId else {
                self.currentTrackId = nil
                self.currentTrackState = nil
                self.initializePlayer(); return
            }
            self.apply(currentTrackId: trackId)
            self.initializePlayer()
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {

//        print("webSocketService trackState: \(trackState)")

//        print("time: \(Date().timeIntervalSince(self.isMasterStateSendDate))")
        guard Date().timeIntervalSince(self.isMasterStateSendDate) > 1.0 else { /*print("BadTime");*/ return }

        self.apply(currentTrackState: trackState)
        if self.state.initialized == false {
            self.initializePlayer()
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool) {

        self.state.blocked = isBlocked

        if isBlocked == false {
            self.playerQueue.replace(addons: [])
        }

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChangeBlockedState: isBlocked)
        })
    }

    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons) {

        switch checkAddons.addons {
        case .addonsIds(let addonsIds): self.apply(addonsIds: addonsIds)
        default: break
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64], flush: Bool) {

        if flush {
            self.playlist.reset(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
        } else {
            self.playlist.update(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
        }

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didUpdateTracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
        })

        guard let currentPlayerItem = self.currentItem,
            self.application.user?.hasPurchase(for: currentPlayerItem.playlistItem.track) == false,
            (currentPlayerItem.playlistItem.track.isFollowAllowFreeDownload && self.application.user?.isFollower(for: currentPlayerItem.playlistItem.track.artist.id) ?? false) == false,
            currentPlayerItem.restrictedTime == nil,
            let currentTrackTotalPlayMSeconds = tracksTotalPlayMSeconds[currentPlayerItem.playlistItem.track.id] else { return }

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChangePlayerItemTotalPlayTime: TimeInterval(currentTrackTotalPlayMSeconds / 1000))
        })

        if let trackMaxPlayMSeconds = currentPlayerItem.trackMaxPlayMSeconds,
            currentTrackTotalPlayMSeconds > trackMaxPlayMSeconds {
            self.playForward()
        }
    }
}

extension Player: ApplicationWatcher {

    func application(_ application: Application, restApiServiceDidChangeReachableState isReachable: Bool) {
        guard isReachable == true, self.config == nil else { return }

        self.loadConfig()
    }

    func disconnect(isPlaying: Bool, isPlayingAddons: Bool) {

        let pauseCompletion: (() -> ()) = { [weak self] () in
            guard isPlayingAddons else {
                self?.webSocketService.disconnect()
                return

            }
            self?.set(trackBlocked: false) { [weak self] (error) in
                self?.webSocketService.disconnect()
            }
        }

        guard isPlaying else { pauseCompletion(); return }

        let playerCurrentItemCurrentTime = self.currentTrackState?.progress ?? 0.0
        let trackState = TrackState(hash: stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
        self.set(trackState: trackState) { (error) in
            pauseCompletion()
        }
    }

    func application(_ application: Application, didChange user: User) {

        guard self.webSocketService.state.isConnected == true else {
            self.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
            return
        }

        let isOtherBlocked = self.state.waitingAddons || self.playerQueue.containsOnlyTrack == false
        let isPlaying = self.state.playing

        self.state.playing = false
        self.player.pause()
        self.addonsPlayTimer?.invalidate()
        self.state.waitingAddons = false
        self.state.initialized = false
        self.state.blocked = false
        self.playlist.resetAddons()
        self.playlist.reset(tracksTotalPlayMSeconds: [ : ])
        self.playerQueue.reset()
        self.player.removeAllItems()

        self.webSocketService.token = Token(token: user.wsToken, isGuest: user.isGuest)

        self.disconnect(isPlaying: isPlaying, isPlayingAddons: isOtherBlocked)
    }

    func application(_ application: Application, didChangeUserToken user: User) {
        guard self.webSocketService.state.isConnected == true else {
            self.webSocketService.connect(with: Token(token: user.wsToken, isGuest: user.isGuest))
            return
        }

        self.webSocketService.token = Token(token: user.wsToken, isGuest: user.isGuest)
        if self.state.initialized == false {
            self.webSocketService.reconnect()
        }
    }

    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        self.playlist.resetAddons()
    }

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {
        guard self.currentItem?.playlistItem.track.id == trackForceToPlayState.trackId,
            trackForceToPlayState.isForcedToPlay == false,
            self.isMaster == true else { return }

        self.playForward()
    }

    func application(_ application: Application, didChangeUserProfile followedArtistsIds: [String], with artistFollowingState: ArtistFollowingState) {
        guard let currentItem = self.currentItem, currentItem.playlistItem.track.artist.id == artistFollowingState.artistId else { return }

        self.playerQueue.playerItemObservable.accept(self.playerItem(for: currentItem.playlistItem))

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChangePlayerItem: self.currentItem)
        })
    }

    func application(_ application: Application, didChangeUserProfile skipAddonsArtistsIds: [String], with skipArtistAddonsState: SkipArtistAddonsState) {

        self.playlist.resetAddons(for: skipArtistAddonsState.artistId)
    }

    func application(_ application: Application, didChangeUserProfile purchasedTracksIds: [Int], added: [Int], removed: [Int]) {
        let changedIdsSet = Set(added).union(removed)
        guard let currentItem = self.currentItem, changedIdsSet.contains(currentItem.playlistItem.track.id) else { return }

        self.playerQueue.playerItemObservable.accept(self.playerItem(for: currentItem.playlistItem))

        self.watchersContainer.invoke({ (observer) in
            observer.player(player: self, didChangePlayerItem: self.currentItem)
        })
    }
}

extension Player {

    func setupMPRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in

            guard self?.state.initialized ?? false else {
                if self?.webSocketService.isReachable == true {
                    self?.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self?.initializationAction = .playCurrent
                    self?.webSocketService.reconnect()
                    return .success
                } else if let _ = self?.currentItem {
                    if self?.player.rate == 0.0 {
                        self?.play()
                        return .success
                    }
                    return .commandFailed
                }
                return .noActionableNowPlayingItem }

            if self?.player.rate == 0.0 {
                self?.play()
                return .success
            }

            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] event in

            guard self?.state.initialized ?? false else {
                if self?.webSocketService.isReachable == true {
                    self?.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self?.initializationAction = .pause
                    return .success
                } else if let _ = self?.currentItem {
                    if self?.player.rate == 1.0 {
                        self?.pause(completion: { [weak self] in
                            if UIApplication.shared.applicationState == .background  {
                                self?.audioSessionIsInterrupted = true
                                self?.webSocketService.disconnect()
                            }
                        })
                        return .success
                    }
                    return .commandFailed
                }
                return .noActionableNowPlayingItem }

            if self?.player.rate == 1.0 {
                self?.pause(completion: { [weak self] in
                    if UIApplication.shared.applicationState == .background  {
                        self?.audioSessionIsInterrupted = true
                        self?.webSocketService.disconnect()
                    }
                })
                return .success
            }

            return .commandFailed
        }

        commandCenter.stopCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard self?.state.initialized ?? false else {
                if self?.webSocketService.isReachable == true {
                    self?.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self?.initializationAction = .pause
                    return .success
                } else if let _ = self?.currentItem {
                    if self?.player.rate == 1.0 {
                        self?.pause(completion: { [weak self] in
                            if UIApplication.shared.applicationState == .background  {
                                self?.audioSessionIsInterrupted = true
                                self?.webSocketService.disconnect()
                            }
                        })
                        return .success
                    }
                    return .commandFailed
                }
                return .noActionableNowPlayingItem }

            if self?.player.rate == 1.0 {
                self?.pause(completion: { [weak self] in
                    if UIApplication.shared.applicationState == .background  {
                        self?.audioSessionIsInterrupted = true
                        self?.webSocketService.disconnect()
                    }
                })
                return .success
            }

            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] event in

            guard self?.state.initialized ?? false else {
                if self?.webSocketService.isReachable == true {
                    self?.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self?.initializationAction = .playForward
                    return .success
                }
                return .noActionableNowPlayingItem }

            self?.playForward()

            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] event in

            guard self?.state.initialized ?? false else {
                if self?.webSocketService.isReachable == true {
                    self?.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                    self?.initializationAction = .playBackward
                    return .success
                } else if self?.canBackward ?? false {
                    self?.playBackward()
                    return .success
                }
                return .noActionableNowPlayingItem }

            self?.playBackward()

            return .success
        }

    }

    func updateMPRemoteInfo() {
        if let currentItem = self.currentItem {
            var nowPlayingInfo = [String : Any]()

            nowPlayingInfo[MPMediaItemPropertyTitle] = currentItem.playlistItem.track.name + " - " + currentItem.playlistItem.track.artist.name
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.currentItemTime ?? 0.0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.playerCurrentItemDuration ?? 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

            // Set the metadata
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}

extension Player {

    var playlistItems: [PlayerPlaylistItem] { return self.playlist.orderedPlaylistItems }


    private func performAdd(tracks: [Track], to playlistPosition: PlaylistPosition, completion: (([PlayerPlaylistItem]?, Error?) -> Void)?) {

        func playlistItem(for playlistPosition: PlaylistPosition) -> PlayerPlaylistItem? {
            switch playlistPosition {
            case .next: return self.playerQueue.playerItem?.playlistItem ?? self.playlist.firstPlaylistItem
            case .last: return self.playlist.lastPlaylistItem
            }
        }

        var tracksPlaylistItemsPatches = self.playlist.playlistItemPatches(for: tracks)
        guard tracksPlaylistItemsPatches.isEmpty == false else { completion?(nil, nil); return }

        var playlistItemsPatches = [String : PlayerPlaylistItemPatch]()

        if let previousPlaylistItem = playlistItem(for: playlistPosition) {
            if let firstTrackPlaylistItemPatch = tracksPlaylistItemsPatches.first {
                var updatedFirstTrackPlaylistItemPatch = firstTrackPlaylistItemPatch
                updatedFirstTrackPlaylistItemPatch.previousKey = PlayerPlaylistItemPatch.KeyType(previousPlaylistItem.key)
                tracksPlaylistItemsPatches[0] = updatedFirstTrackPlaylistItemPatch

                playlistItemsPatches[previousPlaylistItem.key] = PlayerPlaylistItemPatch.patch(for: previousPlaylistItem,
                                                                                               nextPlaylistItemKey: updatedFirstTrackPlaylistItemPatch.key)
            }

            if let nextPlaylistItem = self.playlist.nextPlaylistItem(for: previousPlaylistItem) {
                if let lastTrackPlaylistItemPatch = tracksPlaylistItemsPatches.last {
                    var updatedTrackPlaylistItemPatch = lastTrackPlaylistItemPatch
                    updatedTrackPlaylistItemPatch.nextKey = PlayerPlaylistItemPatch.KeyType(nextPlaylistItem.key)
                    tracksPlaylistItemsPatches[tracksPlaylistItemsPatches.count - 1] = updatedTrackPlaylistItemPatch

                    playlistItemsPatches[nextPlaylistItem.key] = PlayerPlaylistItemPatch.patch(for: nextPlaylistItem,
                                                                                               previousPlaylistItemKey: updatedTrackPlaylistItemPatch.key)

                }
            }
        }

        tracksPlaylistItemsPatches.forEach { playlistItemsPatches[$0.key!] = $0 }

        self.updatePlaylist(playlistItemsPatches: playlistItemsPatches) { [weak self] (error) in

            let tracksKeys = tracksPlaylistItemsPatches.compactMap { return $0.key }

            guard error == nil else {
                self?.playlist.free(reservedPlaylistItemsKeys: tracksKeys)
                completion?(nil, error)
                return
            }
            guard let `self` = self else { completion?(nil , nil); return }

            self.playlist.update(with: playlistItemsPatches)
            self.watchersContainer.invoke({ (observer) in
                observer.playerDidChangePlaylist(player: self)
            })
            completion?(self.playlist.playlistItems(for: tracksKeys), nil)
        }
    }

    func performDelete(playlistItem: PlayerPlaylistItem, completion: ((Error?) -> Void)?) {

        guard self.playlist.playlistItems[playlistItem.key] != nil else { completion?(nil); return }

        let playlistItemPatch: PlayerPlaylistItemPatch? = nil
        var playlistItemsPatches: [String: PlayerPlaylistItemPatch?] = [String: PlayerPlaylistItemPatch?]()
        playlistItemsPatches[playlistItem.key] = playlistItemPatch
        
        var playlistItemToPlay : PlayerPlaylistItem?
        if self.currentItem?.playlistItem == playlistItem {
            playlistItemToPlay = self.findPlayablePlaylistItem(after: playlistItem)
        }

        let previousPlaylistItem = self.playlist.previousPlaylistItem(for: playlistItem)
        let nextPlaylistItem = self.playlist.nextPlaylistItem(for: playlistItem)

        if let previousPlaylistItem = previousPlaylistItem {
            let previousPlaylistItemPatch = PlayerPlaylistItemPatch.patch(for: previousPlaylistItem, nextPlaylistItemKey: nextPlaylistItem?.key)
            playlistItemsPatches[previousPlaylistItem.key] = previousPlaylistItemPatch
        }

        if let nextPlaylistItem = nextPlaylistItem {
            let nextPlaylistItemPatch = PlayerPlaylistItemPatch.patch(for: nextPlaylistItem, previousPlaylistItemKey: previousPlaylistItem?.key)
            playlistItemsPatches[nextPlaylistItem.key] = nextPlaylistItemPatch
        }

        self.updatePlaylist(playlistItemsPatches: playlistItemsPatches) { [weak self] (error) in
            guard let `self` = self, error == nil else { completion?(error); return }
            self.playlist.update(with: playlistItemsPatches)
            self.watchersContainer.invoke({ (observer) in
                observer.playerDidChangePlaylist(player: self)
            })

            guard let currentPlaylistItem = self.currentItem?.playlistItem else { completion?(nil); return }
            guard self.playlist.contains(playlistItem: currentPlaylistItem) == false else { completion?(nil); return }
            let playlistItemToPlay = self.findPlayablePlaylistItem(after: currentPlaylistItem)

            self.setCurrent(playlistItem: playlistItemToPlay, completion: nil)
            completion?(nil)
        }
    }

    func performAction(_ action: Player.Actions, for playlistItem: PlayerPlaylistItem, completion: ((Error?) -> Void)?) {
        guard self.state.initialized == true else { completion?(self.error()); return }

        switch action {
        case .delete: self.performDelete(playlistItem: playlistItem, completion: completion)
        case .playNow:
            self.player.pause()
            self.defferedTrackId = nil

            let currentPlayerItem = self.playerItem(for: playlistItem)
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: true)
            let shouldSendTrackingTimeRequest = self.shouldSendTrackingTimeRequest(for: currentPlayerItem.playlistItem.track)

            self.set(trackId: currentPlayerItem.trackId, trackState: trackState, shouldSendTrackingTimeRequest: shouldSendTrackingTimeRequest, completion: { [weak self] (error) in
                guard error == nil else { completion?(error); return }
                guard let `self` = self else { completion?(nil); return }
                self.playerQueue.replace(playerItem: currentPlayerItem)
                self.replace(playerItems: self.playerQueue.playerItems)

                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayerItem: self.currentItem)
                })

                self.play()
                completion?(nil)
            })
        case .setCurrent:

            let wasPlaying = self.isPlaying
            self.player.pause()
            self.defferedTrackId = nil

            let currentPlayerItem = self.playerItem(for: playlistItem)
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: wasPlaying)
            let shouldSendTrackingTimeRequest = self.shouldSendTrackingTimeRequest(for: currentPlayerItem.playlistItem.track)

            self.set(trackId: currentPlayerItem.trackId, trackState: trackState, shouldSendTrackingTimeRequest: shouldSendTrackingTimeRequest, completion: { [weak self] (error) in
                guard error == nil else { completion?(error); return }
                guard let `self` = self else { completion?(nil); return }
                self.playerQueue.replace(playerItem: currentPlayerItem)
                self.replace(playerItems: self.playerQueue.playerItems)

                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayerItem: self.currentItem)
                })

                if wasPlaying {
                    self.play()
                }
                completion?(nil)
            })
        }
    }
    
    func add(tracks: [Track], at position: PlaylistPosition, completion: (([PlayerPlaylistItem]?, Error?) -> Void)?) {
        guard self.state.initialized == true else { completion?(nil, self.error()); return }

        let unloadedTracks = tracks.filter { return self.playlist.contains(track: $0) == false }
        guard unloadedTracks.isEmpty else {
            self.loadTracks(tracks: unloadedTracks) { [weak self] (error) in
                guard error == nil else { completion?(nil, error); return }
                self?.playlist.add(traksToAdd: unloadedTracks)
                self?.performAdd(tracks: tracks, to: position, completion: completion)
            }
            return
        }

        self.performAdd(tracks: tracks, to: position, completion: completion)
    }

    func performReplace(with tracks: [Track], completion: (([PlayerPlaylistItem]?, Error?) -> Void)?) {

        guard self.state.initialized == true else { completion?(nil, AppError(.notInitialized)); return }

        let tracksPlaylistItemsPatches = self.playlist.playlistItemPatches(for: tracks)
        guard tracksPlaylistItemsPatches.isEmpty == false else { completion?(nil, nil); return }

        var playlistItemsPatches = [String : PlayerPlaylistItemPatch]()

        tracksPlaylistItemsPatches.forEach { playlistItemsPatches[$0.key!] = $0 }

        self.updatePlaylist(playlistItemsPatches: playlistItemsPatches, flushing: true) { [weak self] (error) in

            let tracksKeys = tracksPlaylistItemsPatches.compactMap { return $0.key }

            guard error == nil else {
                self?.playlist.free(reservedPlaylistItemsKeys: tracksKeys)
                completion?(nil, error)
                return
            }
            guard let `self` = self else { completion?(nil , nil); return }

            self.playlist.reset(with: playlistItemsPatches)
            self.watchersContainer.invoke({ (observer) in
                observer.playerDidChangePlaylist(player: self)
            })

            self.state.blocked = false

            if let playlistItemToPlay = self.playlist.firstPlaylistItem {
                self.performAction(.playNow, for: playlistItemToPlay, completion: nil)
            }

            completion?(self.playlist.playlistItems(for: tracksKeys), nil)
        }
    }

    func replace(with tracks: [Track], completion: (([PlayerPlaylistItem]?, Error?) -> Void)?) {

        guard self.state.initialized == true else { completion?(nil, self.error()); return }

        let unloadedTracks = tracks.filter { return self.playlist.contains(track: $0) == false }
        guard unloadedTracks.isEmpty else {
            self.loadTracks(tracks: unloadedTracks) { [weak self] (error) in
                guard error == nil else { completion?(nil, error); return }
                self?.playlist.add(traksToAdd: unloadedTracks)
                self?.performReplace(with: tracks, completion: completion)
            }
            return
        }

        self.performReplace(with: tracks, completion: completion)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}

// MARK: - Karaoke -

extension Player {

    func setPreferredAudioFileType(preferredAudioFileType: AudioFileType) {
        guard self.playerQueue.preferredAudioFileType != preferredAudioFileType else { return }

        if let trackAudioFileType = self.playerQueue.trackAudioFileType, trackAudioFileType != preferredAudioFileType {

            self.playerQueue.replace(preferredAudioFileType: preferredAudioFileType)
            self.replace(playerItems: playerQueue.playerItems)

            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
            self.set(trackState: trackState)

            if let currentQueueItem = self.currentQueueItem {
                self.watchersContainer.invoke({ (observer) in
                    observer.player(player: self, didChangePlayerQueueItem: currentQueueItem)
                })
            }
        } else {
            self.playerQueue.preferredAudioFileType = preferredAudioFileType
        }
    }
}
