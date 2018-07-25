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
}

extension PlayerObserver {

    func player(player: Player, didChangeBlockedState isBlocked: Bool) { }

    func player(player: Player, didChange status: PlayerStatus) { }

    func player(player: Player, didChangePlayState isPlaying: Bool) { }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) { }
    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval) { }
}

class Player: NSObject, Observable {

    typealias ObserverType = PlayerObserver

    let observersContainer = ObserversContainer<PlayerObserver>()

    var isBlocked: Bool = false

    var canForward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return true }

        switch currentQueueItem.content {
        case .addon(let addon): return addon.type == .ArtistBIO || addon.type == .SongCommentary
        default: break
        }

        return true
    }

    var canBackward: Bool {
        guard let currentQueueItem = self.playerQueue.currentItem else { return true }

        switch currentQueueItem.content {
        case .addon(_): return false
        default: break
        }

        return true

    }

    var playerCurrentTrack: Track? {
        return self.playerQueue.track
    }

    var playerCurrentQueueItem: PlayerQueueItem? {
        return self.playerQueue.currentItem
    }

    var playerCurrentTrackDuration: TimeInterval? {
        guard let audioFile = self.playerQueue.track?.audioFile else { return nil }
        return TimeInterval(audioFile.duration)
    }

    var playerCurrentTrackCurrentTime: TimeInterval? {
        guard let currentTrackState = self.currentTrackState else { return self.playerQueue.track != nil ? 0.0 : nil }
        return currentTrackState.progress
    }

    private let stateHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    private var isMaster: Bool {
        guard let currentTrackState = self.currentTrackState else { return false }
        return currentTrackState.hash == self.stateHash
    }
    private var isMasterStateSendDate = Date(timeIntervalSinceNow: -2)

    private(set) var state: PlayerState = []
    private(set) var initializationAction: PlayerInitializationAction = .none

    private var playBackgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    @objc private var player = AVQueuePlayer()
    var timeObserverToken: Any?

    var isPlaying: Bool { return self.player.rate == 1.0 || self.currentTrackState?.isPlaying ?? false == true }

    var playerCurrentItem: AVPlayerItem? { return self.player.currentItem }
    var playerCurrentItemDuration: TimeInterval? {
        guard let duration = self.playerCurrentItem?.duration, duration.value != 0 else { return nil }
        return TimeInterval(CMTimeGetSeconds(duration)).rounded(.towardZero)
    }

    private let restApiService: RestApiService
    private let webSocketService: WebSocketService

    private let playlist: PlayList = PlayList()
    private var playerQueue: PlayerQueue = PlayerQueue()

    private var currentTrackId: TrackId?
    private var currentTrackState: TrackState?

    private var addonsPlayTimer: Timer?


    init(restApiService: RestApiService, webSocketService: WebSocketService) {
        self.restApiService = restApiService
        self.webSocketService = webSocketService

        super.init()

        self.webSocketService.addObserver(self)

        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player.currentItem)

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChange(_:)), name: NSNotification.Name.AVAudioSessionRouteChange, object: AVAudioSession.sharedInstance())

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            let _ = try AVAudioSession.sharedInstance().setActive(true)
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

        if let trackId = self.currentTrackId ?? self.playlist.firstTrackId,
            let track = self.playlist.track(for: trackId) {
            self.playerQueue.replace(track: track, addons: self.currentTrackState != nil ? [] : nil)
            self.replace(playerItems: self.playerQueue.playerItems)
        }

        self.updateMPRemoteInfo()
        if self.initializationAction != .none {
            self.performeInitializationAction()
            self.initializationAction = .none
        }

        self.observersContainer.invoke({ (observer) in
            observer.player(player: self, didChangeStatus: .initialized)
        })
    }

    func updateCurrentTrackState(with timeElapsed:TimeInterval) {
        if self.isMaster && self.state.playing == true && self.playerQueue.containsOnlyTrack {
            let currentTrackState = TrackState(hash: self.stateHash, progress: timeElapsed, isPlaying: self.state.playing)
            self.set(trackState: currentTrackState)
            self.currentTrackState = currentTrackState
        }

        self.updateMPRemoteInfo()

        if self.playerQueue.containsOnlyTrack {
            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItemCurrentTime: timeElapsed)
            })
        }
    }

    func findPlayableTrack(after trackId: TrackId) -> Track? {

        var currentTrackId = trackId
        var track: Track?
        repeat {
            guard let nextTrackId = self.playlist.nextTrackId(for: currentTrackId), nextTrackId.id != trackId.id else { track = nil; break }
            track = self.playlist.track(for: nextTrackId)
            currentTrackId = nextTrackId
        } while track?.isPlayable == false

        return track
    }

    func findPlayableTrack(before trackId: TrackId) -> Track? {

        var currentTrackId = trackId
        var track: Track?
        repeat {
            guard let previousTrackId = self.playlist.previousTrackId(for: currentTrackId), previousTrackId.id != trackId.id else { track = nil; break }
            track = self.playlist.track(for: previousTrackId)
            currentTrackId = previousTrackId
        } while track?.isPlayable == false

        return track
    }


    func loadAddons(for track: Track, completion: ((Error?) -> ())?) {

        self.restApiService.audioAddons(for: [track.id]) { [weak self] (addonsResult) in

            switch addonsResult {
            case .success(let tracksAddons):
                    self?.playlist.add(tracksAddons: tracksAddons)
                    self?.restApiService.artists(with: [track.artist.id], completion: { [weak self] (artistsResult) in

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
        guard self.playerQueue.isReadyToPlay == true else { self.prepareAddons(for: track, completion: completion); return }

        completion?(nil)
    }

    // MARK: - Actions
    func play(completion: (() -> ())? = nil) {
        guard self.state.initialized,
                let track = self.playerQueue.track,
                let trackId = self.playlist.trackId(for: track)
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

        guard let currentTrack = self.playerQueue.track,
            let currentTrackId = self.playlist.trackId(for: currentTrack),
            let nextTrack = self.findPlayableTrack(after: currentTrackId),
            let nextTrackId = self.playlist.trackId(for: nextTrack) else { completion?(); return }

        let isPlaying = self.isPlaying

        let prepareQueueCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { if self?.state.playing ?? false { self?.player.play() }; completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            if self?.state.playing ?? false { self?.player.play() }
            completion?()
        }

        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
        self.set(trackId: nextTrackId, trackState: trackState) { [weak self] (error) in
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

        guard self.state.initialized, self.canBackward else { completion?(); return }

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

        guard let currentTrack = self.playerQueue.track,
            let currentTrackId = self.playlist.trackId(for: currentTrack),
            let previousTrack = self.findPlayableTrack(before: currentTrackId),
            let previousTrackId = self.playlist.trackId(for: previousTrack) else { completion?(); return }

        let prepareQueueCompletion: ((Error?) -> ())? = { [weak self] (error) in
            guard error == nil else { if self?.state.playing ?? false { self?.player.play() }; completion?(); return }
            guard self?.state.waitingAddons == false else { completion?(); return }
            if self?.state.playing ?? false { self?.player.play() }
            completion?()
        }

        let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
        self.set(trackId: previousTrackId, trackState: trackState) { [weak self] (error) in
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
                            self.playAddon(addon: addon, track: track)
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

        if self.stateHash != currentTrackState.hash {
            self.state.playing = false
            self.player.pause()
        }
    }

    func apply(addonsIds: [Int]) {
        guard self.state.waitingAddons == true,
            let track = self.playerQueue.track,
            let addons = self.playlist.addons(for: track, addonsIds: addonsIds) else { return }

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

    //MARK: - WebSocketServiceObserver
    func webSocketServiceDidDisconnect(_ service: WebSocketService) {
        self.state.initialized = false
    }

    func webSocketServiceDidConnect(_ service: WebSocketService) {
        self.state.initialized = false
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) {

        if self.state.initialized {
            self.playlist.add(traks: tracks)
        } else {
            self.playlist.reset(tracks: tracks)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceivePlayList playListItems: [String: PlayListItem]) {

        if self.state.initialized {
            self.playlist.add(playListItems: playListItems)
        } else {
            self.playlist.reset(playListItems: playListItems)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {

        if self.state.initialized {
            guard let trackId = trackId else { return }
            self.apply(currentTrackId: trackId)
        } else {
            guard let trackId = trackId else { self.initializePlayer(); return }
            self.apply(currentTrackId: trackId)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {

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
}

extension Player: ApplicationObserver {
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
                    return .success                    
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
                }
                return .noActionableNowPlayingItem }

            if self?.player.rate == 1.0 {
                self?.pause()
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
                }
                return .noActionableNowPlayingItem }

            if self?.player.rate == 1.0 {
                self?.pause()
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
                }
                return .noActionableNowPlayingItem }

            self?.playBackward()

            return .success
        }

    }

    func updateMPRemoteInfo() {
        if let currentTrack = self.playerCurrentTrack {
            var nowPlayingInfo = [String : Any]()

            nowPlayingInfo[MPMediaItemPropertyTitle] = currentTrack.name + " - " + currentTrack.artist.name
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.playerCurrentTrackCurrentTime ?? 0.0
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.playerCurrentTrackDuration ?? 0.0
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

            // Set the metadata
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}

