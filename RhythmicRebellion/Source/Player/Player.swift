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

private var playerKVOContext = 0

public enum PlayerStatus : Int {

    case unknown
    case initialized
    case failed
}

public enum PlayerInitializationAction : Int {

    case none
    case playCurrent
    case pause
    case playForward
    case playBackward
}

protocol PlayerObserver: class {

    func player(player: Player, didChangeBlockedState isBlocked: Bool)

    func player(player: Player, didChangeStatus status: PlayerStatus)

    func player(player: Player, didChangePlayState isPlaying: Bool)

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem)
    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval)
    func playerDidChangePlaylist(player: Player)
}

extension PlayerObserver {

    func player(player: Player, didChangeBlockedState isBlocked: Bool) { }

    func player(player: Player, didChange status: PlayerStatus) { }

    func player(player: Player, didChangePlayState isPlaying: Bool) { }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) { }
    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval) { }
    
    func playerDidChangePlaylist(player: Player) {}
}

class Player: NSObject, Observable {

    enum PlaylistPosition {
        case next
        case last
    }

    enum Actions {
        case add(PlaylistPosition)
        case playNow
        case setCurrent
        case delete
    }

    typealias ObserverType = PlayerObserver

    let observersContainer = ObserversContainer<PlayerObserver>()

    var isBlocked: Bool = false

    var canForward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized }

        switch currentQueueItem.content {
        case .addon(let addon): return addon.type == .artistBIO || addon.type == .songCommentary
        default: break
        }

        return self.state.initialized
    }

    var canBackward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return self.state.initialized }

        switch currentQueueItem.content {
        case .addon(_): return false
        case .track(_), .stub(_):
            guard let trackProgress = self.currentTrackState?.progress, trackProgress > 0.3 else { return self.state.initialized }
            return true
        }
    }

    var canSeek: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return false }

        switch currentQueueItem.content {
        case .addon(_), .stub(_): return false
        case .track(_): return self.state.waitingAddons == false
        }
    }

    var playerCurrentTrack: PlayerTrack? {
        return self.playerQueue.track
    }

    var playerCurrentQueueItem: PlayerQueueItem? {
        return self.playerQueue.currentItem
    }

    var playerCurrentTrackDuration: TimeInterval? {
        guard let audioFile = self.playerQueue.track?.track.audioFile else { return nil }
        return TimeInterval(audioFile.duration)
    }

    var playerCurrentTrackCurrentTime: TimeInterval? {
        guard let currentTrackState = self.currentTrackState else { return self.playerQueue.track != nil ? 0.0 : nil }
        return currentTrackState.progress
    }

    var playerCurrentItemRestrictedTime: TimeInterval? {
        guard let currentTrack = self.playerQueue.track?.track else { return nil }
        return self.restrictedTime(for: currentTrack)
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

    var isPlaying: Bool { return self.player.rate == 1.0 || self.currentTrackState?.isPlaying ?? false == true }

    var playerCurrentItem: AVPlayerItem? { return self.player.currentItem }
    var playerCurrentItemDuration: TimeInterval? {
        guard let duration = self.playerCurrentItem?.duration, duration.value != 0 else { return nil }
        return TimeInterval(CMTimeGetSeconds(duration)).rounded(.towardZero)
    }

    private let application: Application
    private var webSocketService: WebSocketService { return self.application.webSocketService }

    private let playlist: PlayerPlaylist = PlayerPlaylist()
    private var playerQueue: PlayerQueue = PlayerQueue()

    public var currentTrackId: TrackId?
    private var currentTrackState: TrackState?

    private var addonsPlayTimer: Timer?


    init(with application: Application) {

        self.application = application

        super.init()

        self.application.addObserver(self)
        self.webSocketService.addObserver(self)

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("an error occurred when audio session category.\n \(error)")
        }

        addObserver(self, forKeyPath: #keyPath(Player.player.rate), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem.status), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(Player.player.currentItem.duration), options: [.new, .initial], context: &playerKVOContext)

        let interval = CMTimeMake(1, 1)
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
        self.webSocketService.removeObserver(self)
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

        if self.currentTrackId == nil, let trackId = self.playlist.firstTrackId,
            let track = self.playlist.track(for: trackId) {
            self.playerQueue.replace(track: track, addons: self.currentTrackState != nil ? [] : nil)
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


        self.observersContainer.invoke({ (observer) in
            observer.player(player: self, didChangeStatus: .initialized)
        })
    }

    func restrictedTime(for track: Track) -> TimeInterval? {
        guard track.isFreeForPlaylist == false else { return nil }
        guard let _ = self.application.user as? FanUser else { return self.guestRestrictedTime(for: track) }


        switch track.previewType {
        case .full:
            guard let previewLimitTimes = track.previewLimitTimes else { return nil }
            guard let trackDuration = track.audioFile?.duration, previewLimitTimes > 0 else { return TimeInterval(45) }
            guard let trackTotalPlayMSeconds = self.totalPlayMSeconds(for: track) else { return nil }

            let trackMaxPlayMSeconds = UInt64(trackDuration * 1000 * previewLimitTimes)
            guard trackMaxPlayMSeconds > trackTotalPlayMSeconds else { return nil }

            return TimeInterval(45)

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

    func totalPlayMSeconds(for track: Track) -> UInt64? {
        return self.playlist.totalPlayMSeconds(for: track)
    }

    func updateCurrentTrackState(with timeElapsed:TimeInterval) {
        if self.isMaster && self.state.playing == true && self.playerQueue.containsOnlyTrack && self.playerQueue.trackStub == nil {
            let currentTrackState = TrackState(hash: self.stateHash, progress: timeElapsed, isPlaying: self.state.playing)
            self.set(trackState: currentTrackState)
            self.currentTrackState = currentTrackState
        }

        self.updateMPRemoteInfo()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.previousTrackCommand.isEnabled = self.canBackward

        if self.playerQueue.containsOnlyTrack && self.playerQueue.trackStub == nil{
            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItemCurrentTime: timeElapsed)
            })
        }
    }

    func findPlayableTrack(after trackId: TrackId) -> PlayerTrack? {

        var currentTrackId = trackId
        var track: PlayerTrack?
        repeat {
            guard let nextTrackId = self.playlist.nextTrackId(for: currentTrackId), nextTrackId.key != trackId.key else { track = nil; break }
            track = self.playlist.track(for: nextTrackId)
            currentTrackId = nextTrackId
        } while track?.track.isPlayable == false

        return track
    }

    func findPlayableTrack(before trackId: TrackId) -> PlayerTrack? {
        var currentTrackId = trackId
        var track: PlayerTrack?
        repeat {
            guard let previousTrackId = self.playlist.previousTrackId(for: currentTrackId), previousTrackId.key != trackId.key else { track = nil; break }
            track = self.playlist.track(for: previousTrackId)
            currentTrackId = previousTrackId
        } while track?.track.isPlayable == false

        return track
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

            self?.state.waitingAddons = true
            self?.addonsPlayTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                                         repeats: false,
                                                         block: { [weak self] (timer) in
                                                            self?.state.waitingAddons = false
                                                            self?.set(trackBlocked: false)
                                                            self?.state.playing = true
                                                            self?.player.play()
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
        guard self.state.initialized, let track = self.playerQueue.track else { completion?(AppError(.notInitialized)); return }

        guard self.playerQueue.isReadyToPlay == true else {

            guard let config = self.config, let stubTrackAudioFileReason = self.application.user?.stubTrackAudioFileReason(for: track.track) else {
                self.prepareAddons(for: track.track, completion: completion)
                return
            }

            switch stubTrackAudioFileReason {
            case .noPreview:
                self.playerQueue.replace(track: track, trackStub: config.noPreviewAudioFile)
            case .censorship:
                self.playerQueue.replace(track: track, trackStub: config.explicitMaterialAudioFile)
            }

            self.replace(playerItems: playerQueue.playerItems)
            if self.state.playing == true { self.player.play() }

            completion?(nil)
            return
        }

        completion?(nil)
    }

    // MARK: - Actions
    func play(completion: (() -> ())? = nil) {
        guard self.state.initialized,
                let trackId = self.playerQueue.track?.trackId
                else {
                    self.state.playing = true
                    self.player.play()
                    completion?()
                    return
        }

        self.state.playing = true

        let prepareQueueCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { self?.player.play(); completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            self?.player.play()
            completion?()
        }

        guard self.currentTrackId != nil  else {
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: self.state.playing)
            self.set(trackId: trackId, trackState: trackState) { [weak self] (error) in
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

        guard self.state.initialized, self.playerCurrentItem != nil else { completion?(); return }

        let playerCurrentItemCurrentTime = self.currentTrackState?.progress ?? 0.0
        let trackState = TrackState(hash: self.stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
        self.set(trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self else { completion?(); return }

            strongSelf.observersContainer.invoke({ (observer) in
                observer.player(player: strongSelf, didChangePlayState: trackState.isPlaying)
            })

            completion?()
        }
    }
    
    func clearPlaylist() {
        //NOTE: 
        var playlistItems: [String: PlayerPlaylistItem?] = [String: PlayerPlaylistItem?]()
//        playlistItems = self.playlist.playListItems.mapValues { (item) -> PlayerPlaylistItem? in
//            let nilItem: PlayerPlaylistItem? = nil
//            return nilItem
//        }
        
//        var item = self.playlist.playListItems["8ufOt"] ?? nil
//        item?.nextTrackKey = nil
//        playlistItems["8ufOt"] = item
        playlistItems["dummy"] = PlayerPlaylistItem(id: 102, trackKey: "dummy")
        
        
        self.updatePlaylist(playlistItems: playlistItems, flushing: true) { [weak self] (error) in
            guard error == nil else { return }
            self?.playlist.update(playListItems: playlistItems)
            if let strongSelf = self {
                strongSelf.observersContainer.invoke({ (observer) in
                    observer.playerDidChangePlaylist(player: strongSelf)
                })
            }
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

        guard let currentTrackId = self.playerQueue.track?.trackId,
            let nextTrack = self.findPlayableTrack(after: currentTrackId) else { completion?(); return }

        let isPlaying = self.isPlaying

        let prepareQueueCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { if self?.state.playing ?? false { self?.player.play() }; completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            if self?.state.playing ?? false { self?.player.play() }
            completion?()
        }

        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
        self.set(trackId: nextTrack.trackId, trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(); return }

            strongSelf.player.pause()
            strongSelf.playerQueue.replace(track: nextTrack)
            strongSelf.replace(playerItems: strongSelf.playerQueue.playerItems)

            strongSelf.state.playing = isPlaying
            if isPlaying {
                strongSelf.preparePlayerQueueToPlay(completion: prepareQueueCompletion)
            }
        }
    }

    func playBackward(completion: (() -> ())? = nil) {

        guard self.canBackward else { completion?(); return }

        let isPlaying = self.isPlaying
        let playerCurrentItemCurrentTime = self.playerCurrentTrackCurrentTime ?? 0.0

        guard playerCurrentItemCurrentTime <= TimeInterval(3.0) else {
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
            self.set(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self else { completion?(); return }

                strongSelf.currentTrackState = trackState
                strongSelf.updateMPRemoteInfo()

                strongSelf.observersContainer.invoke({ (observer) in
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

        guard self.state.initialized else { completion?(); return }
        guard let currentTrackId = self.playerQueue.track?.trackId,
            let previousTrack = self.findPlayableTrack(before: currentTrackId) else { completion?(); return }

        let prepareQueueCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { if self?.state.playing ?? false { self?.player.play() }; completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            if self?.state.playing ?? false { self?.player.play() }
            completion?()
        }

        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
        self.set(trackId: previousTrack.trackId, trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(); return }

            strongSelf.player.pause()
            strongSelf.playerQueue.replace(track: previousTrack)
            strongSelf.replace(playerItems: strongSelf.playerQueue.playerItems)

            if isPlaying {
                strongSelf.state.playing = isPlaying
                strongSelf.preparePlayerQueueToPlay(completion: prepareQueueCompletion)
            }
        }
    }

    func seek(to timeInterval: TimeInterval) {
        guard self.canSeek else { return }

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
            })
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

        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            self.audioSessionIsInterrupted = true
            let pauseBackgroundtask = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            self.state.playingBeforeAudioSessionInterruption = self.state.playing
            self.pause { UIApplication.shared.endBackgroundTask(pauseBackgroundtask) }

        } else if type == .ended {

            self.player.pause()
            self.audioSessionIsInterrupted = false
            var options: AVAudioSessionInterruptionOptions = []

            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
            }

            if self.webSocketService.isConnected == false {
                self.playBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                if options.contains(.shouldResume) && self.state.playingBeforeAudioSessionInterruption {
                    self.initializationAction = .playCurrent
                }
                self.webSocketService.reconnect()
            } else {
                if options.contains(.shouldResume) && self.state.playingBeforeAudioSessionInterruption {
                    self.player.play()
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
            if let audioSessionRouteChangeReason = AVAudioSessionRouteChangeReason(rawValue: notificationUserInfo[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0) {

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

            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayState: self.player.rate == 1.0)
            })

        } else if keyPath == #keyPath(Player.player.currentItem) {
            guard let currrentQueueItem = self.playerCurrentQueueItem else { return }
            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerQueueItem: currrentQueueItem)
            })
        } else if keyPath == #keyPath(Player.player.currentItem.status) {
            switch self.player.currentItem?.status {
            case .readyToPlay?: if self.state.playing == true {

                if let currentQueueItem = self.playerQueue.currentItem {
                    switch currentQueueItem.content {
                    case .addon(let addon):
                        if let track = self.playerCurrentTrack {
                            self.playAddon(addon: addon, track: track.track)
                        }
                    default: break
                    }
                }

                self.player.play()
                }
            default: break
            }
        } else if keyPath == #keyPath(Player.player.currentItem.duration) {
            guard let currrentQueueItem = self.playerCurrentQueueItem else { return }
            self.observersContainer.invoke({ (observer) in
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

extension Player: WebSocketServiceObserver {

    // MARK: - Apply State
    func apply(currentTrackId: TrackId) {

        guard self.currentTrackId != currentTrackId else { return }

        self.state.playing = false
        self.player.pause()

        guard let track = self.playlist.track(for: currentTrackId) else { return }

        self.currentTrackState = nil
        self.currentTrackId = currentTrackId
        self.playerQueue.replace(track: track)
        self.replace(playerItems: self.playerQueue.playerItems)
    }

    func apply(currentTrackState: TrackState) {

        self.currentTrackState = currentTrackState

        if currentTrackState.progress > 1.0 {
            self.playerQueue.replace(addons: [])
        }

        if self.stateHash != currentTrackState.hash {
            self.state.playing = false
            self.player.pause()
        }
    }

    func apply(addonsIds: [Int]) {
        guard self.state.waitingAddons == true,
            let track = self.playerQueue.track,
            let addons = self.playlist.addons(for: track.track, addonsIds: addonsIds) else { return }

        self.playerQueue.replace(track: track, addons: addons)
        self.replace(playerItems: playerQueue.playerItems)
        self.state.waitingAddons = false

        if self.state.playing == true { self.player.play() }

        self.addonsPlayTimer?.invalidate()
    }

    //MARK: - Set State
    func set(trackId: TrackId, trackState: TrackState, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.setCurrentTrack(trackId: trackId)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard error == nil else { completion?(error); return }

            self?.currentTrackId = trackId
            self?.isMasterStateSendDate = Date()
            self?.set(trackState: trackState, completion: completion)
        }
    }

    func set(trackState: TrackState, completion: ((Error?) -> ())? = nil) {

        let webSocketCommand = WebSocketCommand.setTrackState(trackState: trackState)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard error == nil else { completion?(error); return }

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

    func loadTrack(track: Track, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.loadTrack(track: track)

        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    func updatePlaylist(playlistItems: [String: PlayerPlaylistItem?], flushing: Bool = false, completion: ((Error?) -> ())? = nil) {
        var webSocketCommand = WebSocketCommand.updatePlaylist(playlistsItems: playlistItems)
        if flushing {
            webSocketCommand.flush = true
        }
        self.webSocketService.sendCommand(command: webSocketCommand, completion: completion)
    }

    //MARK: - WebSocketServiceObserver
    func webSocketServiceDidDisconnect(_ service: WebSocketService) {
        self.state.initialized = false

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.nextTrackCommand.isEnabled = self.canForward
        commandCenter.previousTrackCommand.isEnabled = self.canBackward

        if self.audioSessionIsInterrupted == false && self.webSocketService.isReachable {
            self.webSocketService.reconnect()
        }
    }

    func webSocketServiceDidConnect(_ service: WebSocketService) {
        self.state.initialized = false
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) {
        if self.state.initialized {
            self.playlist.add(traksToAdd: tracks)
        } else {
            self.playlist.reset(tracks: tracks)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceivePlaylist playListItems: [String: PlayerPlaylistItem?]) {
        if self.state.initialized {
            self.playlist.add(playListItems: playListItems)
        } else {
            self.playlist.reset(playListItems: playListItems)
        }
        self.observersContainer.invoke({ (observer) in
            observer.playerDidChangePlaylist(player: self)
        })
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {

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
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {

//        print("webSocketService trackState: \(trackState)")

        print("time: \(Date().timeIntervalSince(self.isMasterStateSendDate))")
        guard Date().timeIntervalSince(self.isMasterStateSendDate) > 1.0 else { print("BadTime"); return }

        self.apply(currentTrackState: trackState)
        if self.state.initialized == false {
            self.initializePlayer()
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackBlock isBlocked: Bool) {

        self.isBlocked = isBlocked

        if isBlocked == false {
            self.playerQueue.replace(addons: [])
        }

        self.observersContainer.invoke({ (observer) in
            observer.player(player: self, didChangeBlockedState: isBlocked)
        })
    }

    func webSocketService(_ service: WebSocketService, didReceiveCheckAddons checkAddons: CheckAddons) {

        switch checkAddons.addons {
        case .addonsIds(let addonsIds): self.apply(addonsIds: addonsIds)
        default: break
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracksTotalPlayTime tracksTotalPlayMSeconds: [Int : UInt64]) {
        self.playlist.reset(tracksTotalPlayMSeconds: tracksTotalPlayMSeconds)
    }
}

extension Player: ApplicationObserver {

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

        guard self.webSocketService.isConnected == true else {
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

        self.webSocketService.token = Token(token: user.wsToken, isGuest: user.isGuest)

        self.disconnect(isPlaying: isPlaying, isPlayingAddons: isOtherBlocked)
    }

    func application(_ application: Application, didChange listeningSettings: ListeningSettings) {
        self.playlist.resetAddons()
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
                } else if let _ = self?.playerCurrentTrack {
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
                } else if let _ = self?.playerCurrentTrack {
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
                } else if let _ = self?.playerCurrentTrack {
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
        if let currentTrack = self.playerCurrentTrack {
            var nowPlayingInfo = [String : Any]()

            nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack.track.name + " - " + currentTrack.track.artist.name
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.playerCurrentTrackCurrentTime ?? 0.0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.playerCurrentTrackDuration ?? 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

            // Set the metadata
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}

extension Player {

    var tracks: [PlayerTrack] { return self.playlist.orderedTracks }

    private func performAdd(track: Track, to playlistPosition: PlaylistPosition, completion: ((PlayerTrack?, Error?) -> Void)?) {
        guard let currentTrackId = self.currentTrackId ?? self.playlist.firstTrackId else { return }
        
        switch playlistPosition {
        case .next:
            var previousPlaylistItem = self.playlist.playListItem(for: currentTrackId)
            var nextPlaylistItem = self.playlist.playListItem(for: self.playlist.nextTrackId(for: currentTrackId))
            var trackPlaylistItem = self.playlist.makePlayListItem(for: track)

            previousPlaylistItem!.nextTrackKey = trackPlaylistItem.trackKey
            trackPlaylistItem.previousTrackKey = previousPlaylistItem?.trackKey

            trackPlaylistItem.nextTrackKey = nextPlaylistItem?.trackKey
            nextPlaylistItem?.previousTrackKey = trackPlaylistItem.trackKey

            var playlistItems: [String: PlayerPlaylistItem] = [String: PlayerPlaylistItem]()
            if previousPlaylistItem != nil { playlistItems[previousPlaylistItem!.trackKey] = previousPlaylistItem }
            if nextPlaylistItem != nil { playlistItems[nextPlaylistItem!.trackKey] = nextPlaylistItem }
            playlistItems[trackPlaylistItem.trackKey] = trackPlaylistItem

            self.updatePlaylist(playlistItems: playlistItems) { [weak self] (error) in
                guard let `self` = self, error == nil else { completion?(nil, error); return }
                self.playlist.add(playListItems: playlistItems)
                self.observersContainer.invoke({ (observer) in
                    observer.playerDidChangePlaylist(player: self)
                })
                completion?(PlayerTrack(track: track, playlistItem: trackPlaylistItem), nil)
            }


        case .last:
            var previousPlaylistItem = self.playlist.lastPlayListItem
            guard previousPlaylistItem != nil else { completion?(nil, nil); return } //Maybe we should add some error here
            var trackPlaylistItem = self.playlist.makePlayListItem(for: track)

            previousPlaylistItem!.nextTrackKey = trackPlaylistItem.trackKey
            trackPlaylistItem.previousTrackKey = previousPlaylistItem?.trackKey

            let playlistItems: [String: PlayerPlaylistItem] = [previousPlaylistItem!.trackKey : previousPlaylistItem!,
                                                               trackPlaylistItem.trackKey : trackPlaylistItem]

            self.updatePlaylist(playlistItems: playlistItems) { [weak self] (error) in
                guard error == nil else { completion?(nil, error); return }
                self?.playlist.add(playListItems: playlistItems)
                if let strongSelf = self {
                    strongSelf.observersContainer.invoke({ (observer) in
                        observer.playerDidChangePlaylist(player: strongSelf)
                    })
                }
                completion?(PlayerTrack(track: track, playlistItem: trackPlaylistItem), nil)
            }
        }
    }

    func performDelete(track: PlayerTrack, completion: ((Error?) -> Void)?) {
        let trackPlaylistItem: PlayerPlaylistItem? = nil
        var playlistItems: [String: PlayerPlaylistItem?] = [String: PlayerPlaylistItem?]()
        playlistItems[track.playlistItem.trackKey] = trackPlaylistItem
        
        var trackToPlay : PlayerTrack?
        if self.currentTrackId?.key == track.playlistItem.trackKey {
            trackToPlay = self.findPlayableTrack(after: track.trackId)
        }
        
        var prevItem : PlayerPlaylistItem?
        var nextItem : PlayerPlaylistItem?
        if let prevKey = track.playlistItem.previousTrackKey, let prevCachedItem = self.playlist.playListItems[prevKey] {
            prevItem = prevCachedItem
        }
        
        if let nextKey = track.playlistItem.nextTrackKey, let nextCachedItem = self.playlist.playListItems[nextKey] {
            nextItem = nextCachedItem
        }

        prevItem?.nextTrackKey = nextItem?.trackKey
        nextItem?.previousTrackKey = prevItem?.trackKey
        
        if prevItem != nil { playlistItems[prevItem!.trackKey] = prevItem }
        if nextItem != nil { playlistItems[nextItem!.trackKey] = nextItem }
        
        self.updatePlaylist(playlistItems: playlistItems) { [weak self] (error) in
            guard error == nil else { completion?(error); return }
            self?.playlist.update(playListItems: playlistItems)
            if let strongSelf = self {
                strongSelf.observersContainer.invoke({ (observer) in
                    observer.playerDidChangePlaylist(player: strongSelf)
                })
            }
            
            if let nextPlayTrack = trackToPlay {
                self?.performAction(.setCurrent, for: nextPlayTrack, completion: nil)
            }
            
            completion?(nil)
        }
    }

    func performAction(_ action: Player.Actions, for playerTrack: PlayerTrack, completion: ((Error?) -> Void)?) {
        switch action {
        case .add(let position):
            //Assume player track come from player's playlist
            self.performAdd(track: playerTrack.track, to: position) { (playerTrack, error) in
                completion?(error)
            }
        case .delete:
            self.performDelete(track: playerTrack, completion: completion)
        case .playNow:
            self.player.pause()
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: true)
            self.set(trackId: playerTrack.trackId, trackState: trackState, completion: { [weak self] (error) in
                guard error == nil else { completion?(error); return }
                guard let `self` = self else { completion?(nil); return }
                self.playerQueue.replace(track: playerTrack)
                self.replace(playerItems: self.playerQueue.playerItems)
                self.play()
                completion?(nil)
            })
        case .setCurrent:
            let wasPlaying = self.isPlaying
            self.player.pause()
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: wasPlaying)
            self.set(trackId: playerTrack.trackId, trackState: trackState, completion: { [weak self] (error) in
                guard error == nil else { completion?(error); return }
                guard let `self` = self else { completion?(nil); return }
                self.playerQueue.replace(track: playerTrack)
                self.replace(playerItems: self.playerQueue.playerItems)
                if wasPlaying {
                    self.play()
                }
                completion?(nil)
            })
        }
    }
    
    func add(track: Track, at position: PlaylistPosition, completion: ((PlayerTrack?, Error?) -> Void)?) {
        guard self.playlist.contains(track: track) else {
            self.loadTrack(track: track) { [weak self] (error) in
                guard error == nil else { completion?(nil, error); return }
                self?.playlist.add(traksToAdd: [track])
                self?.performAdd(track: track, to: position, completion: completion)
            }
            return
        }
        self.performAdd(track: track, to: position, completion: completion)
    }
}
