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

    func player(player: Player, didChangeStatus status: PlayerStatus)

    func player(player: Player, didChangePlayState isPlaying: Bool)

    func player(player: Player, didChangePlayerItem track: Track)
    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval)
}

extension PlayerObserver {
    func player(player: Player, didChange status: PlayerStatus) { }

    func player(player: Player, didChangePlayState isPlaying: Bool) { }

    func player(player: Player, didChangePlayerItem track: Track) { }
    func player(player: Player, didChangePlayerItemCurrentTime Time: TimeInterval) { }
}

class Player: NSObject, Observable {

    typealias ObserverType = PlayerObserver

    let observersContainer = ObserversContainer<PlayerObserver>()

    private let webSocketService: WebSocketService

    let playlist: PlayList = PlayList()
    var currentTrackId: TrackId?
    var currentTrack: Track?
    var currentTrackState: TrackState?

    private let stateHash = String(randomWithLength: 11, allowedCharacters: .alphaNumeric)
    var isMaster: Bool {
        guard let currentTrackState = self.currentTrackState else { return false }
        return currentTrackState.hash == self.stateHash
    }
    private var isMasterStateSendDate = Date(timeIntervalSinceNow: -1)

    private(set) var status: PlayerStatus = .unknown
    private(set) var initializationAction: PlayerInitializationAction = .none

    private var playBackgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    @objc private var player = AVPlayer()
    var timeObserverToken: Any?
    var shouldStartPlay: Bool = false

    var isPlaying: Bool { return self.player.rate == 1.0 || self.currentTrackState?.isPlaying ?? false == true }

    var playerCurrentItem: AVPlayerItem? { return self.player.currentItem }
    var playerCurrentItemDuration: TimeInterval? {
        guard let duration = self.playerCurrentItem?.duration, duration.value != 0 else { return nil }
        return TimeInterval(CMTimeGetSeconds(duration)).rounded(.towardZero)
    }
    var playerCurrentItemCurrentTime: TimeInterval? {
        guard let currentTrackState = self.currentTrackState else { return nil }
        return currentTrackState.progress
    }


    init(with webSocketService: WebSocketService) {
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

    func updateStatus(status: PlayerStatus) {
        guard self.status != status else { return }

        self.status = status

        switch status {
        case .initialized:
            self.updateMPRemoteInfo()
            if self.initializationAction != .none {
                self.performeInitializationAction()
                self.initializationAction = .none
            }

        default: break
        }

        self.observersContainer.invoke({ (observer) in
            observer.player(player: self, didChangeStatus: self.status)
        })
    }

    func updateCurrentTrackState(with timeElapsed:TimeInterval) {
        if self.isMaster && self.shouldStartPlay == true {
            let currentTrackState = TrackState(hash: self.stateHash, progress: timeElapsed, isPlaying: self.player.rate == 1.0)
            self.sendTrackState(trackState: currentTrackState)
            self.currentTrackState = currentTrackState
        }

        self.updateMPRemoteInfo()

        self.observersContainer.invoke({ (observer) in
            observer.player(player: self, didChangePlayerItemCurrentTime: timeElapsed)
        })
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

    func prepareToPlay(trackId: TrackId) {

        guard let track = self.playlist.track(for: trackId), track.isPlayable == true else {
            if let firstPlayableTrack = self.findPlayableTrack(after: trackId) {
                self.prepareToPlay(track: firstPlayableTrack)
            }
            return
        }

        self.prepareToPlay(track: track)
    }

    func prepareToPlay(track: Track) {

        self.currentTrack = track

        guard let audioFile = track.audioFile, let playItemURL = URL(string: audioFile.urlString) else { return }
        let playerItem = AVPlayerItem(url: playItemURL)

        if self.player.currentItem != playerItem {
            self.player.replaceCurrentItem(with: playerItem)
        }

        self.updateMPRemoteInfo()
    }


    // MARK: - Actions
    func play(completion: (() -> ())? = nil) {
        guard self.status == .initialized, let currentTrack = self.currentTrack, self.playerCurrentItem != nil else {
            completion?()
            return
        }

        if self.currentTrackId == nil {

            if let trackId = self.playlist.trackId(for: currentTrack) {
                let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: true)
                self.sendTrackId(trackId: trackId, trackState: trackState) { [weak self] (error) in
                    guard let strongSelf = self, error == nil else { completion?(); return }

                    strongSelf.shouldStartPlay = true
                    strongSelf.currentTrackId = trackId
                    strongSelf.currentTrackState = trackState
                    strongSelf.player.play()
                    completion?()
                }
            }
        } else if let currentTrackState = self.currentTrackState {

            let trackState = TrackState(hash: self.stateHash, progress: currentTrackState.progress, isPlaying: true)
            self.sendTrackState(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self, error == nil else { completion?(); return }

                strongSelf.currentTrackState = trackState

                let time = CMTime(seconds: Double(currentTrackState.progress), preferredTimescale: Int32(kCMTimeMaxTimescale))
                strongSelf.player.currentItem?.seek(to: time, completionHandler: { [weak self] (success) in
                    guard success == true else { completion?(); return }
                    self?.shouldStartPlay = true
                    self?.player.play()
                    completion?()
                })
            }
        } else {

            let trackState = TrackState(hash: self.stateHash, progress:0.0, isPlaying: true)
            self.sendTrackState(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self, error == nil else { completion?(); return }

                strongSelf.currentTrackState = trackState
                strongSelf.shouldStartPlay = true
                strongSelf.player.play()
                completion?()
            }
        }
    }

    func pause(completion: (() -> ())? = nil) {
        guard self.status == .initialized, self.playerCurrentItem != nil else { completion?(); return }

        self.player.pause()
        self.shouldStartPlay = false

        let playerCurrentItemCurrentTime = self.currentTrackState?.progress ?? 0.0
        let trackState = TrackState(hash: self.stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
        self.sendTrackState(trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(); return }

            strongSelf.currentTrackState = trackState
            strongSelf.observersContainer.invoke({ (observer) in
                observer.player(player: strongSelf, didChangePlayState: trackState.isPlaying)
            })

            completion?()
        }
    }

    func playForward(completion: (() -> ())? = nil) {
        guard let currentTrack = self.currentTrack,
            let currentTrackId = self.playlist.trackId(for: currentTrack),
            let nextTrack = self.findPlayableTrack(after: currentTrackId),
            let nextTrackId = self.playlist.trackId(for: nextTrack) else { completion?(); return }


        let isPlaying = self.isPlaying
        let playerCurrentItemCurrentTime = self.playerCurrentItemCurrentTime ?? 0.0
        let trackState = TrackState(hash: self.stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
        self.sendTrackState(trackState: trackState) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(); return }

            let nextTrackState = TrackState(hash: strongSelf.stateHash, progress: 0.0, isPlaying: isPlaying)
            strongSelf.sendTrackId(trackId: nextTrackId, trackState: nextTrackState, completion: { [weak self] (error) in
                guard let strongSelf = self, error == nil else { completion?(); return }

                strongSelf.currentTrackId = nextTrackId
                strongSelf.currentTrackState = nextTrackState
                strongSelf.shouldStartPlay = isPlaying
                strongSelf.prepareToPlay(track: nextTrack)
                if isPlaying { strongSelf.player.play() }
                completion?();
            })
        }
    }

    func playBackward(completion: (() -> ())? = nil) {
        guard let currentTrack = self.currentTrack,
            let currentTrackId = self.playlist.trackId(for: currentTrack),
            let previousTrack = self.findPlayableTrack(before: currentTrackId),
            let previousTrackId = self.playlist.trackId(for: previousTrack) else { completion?(); return }


        let isPlaying = self.isPlaying
        let playerCurrentItemCurrentTime = self.playerCurrentItemCurrentTime ?? 0.0

        if playerCurrentItemCurrentTime > TimeInterval(3.0) {
            let trackState = TrackState(hash: self.stateHash, progress: 0.0, isPlaying: isPlaying)
            self.sendTrackState(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self, error == nil else { completion?(); return }

                strongSelf.currentTrackState = trackState

                strongSelf.updateMPRemoteInfo()

                strongSelf.observersContainer.invoke({ (observer) in
                    observer.player(player: strongSelf, didChangePlayerItemCurrentTime: trackState.progress)
                })

                let time = CMTime(seconds: Double(0.0), preferredTimescale: Int32(kCMTimeMaxTimescale))
                strongSelf.player.currentItem?.seek(to: time, completionHandler: { [weak self] (success) in
                    guard success == true else { completion?(); return }

                    self?.shouldStartPlay = isPlaying
                    if isPlaying { self?.player.play() }
                    completion?()
                })
            }
        } else {

            let trackState = TrackState(hash: self.stateHash, progress: playerCurrentItemCurrentTime, isPlaying: false)
            self.sendTrackState(trackState: trackState) { [weak self] (error) in
                guard let strongSelf = self, error == nil else { completion?(); return }

                let previousTrackState = TrackState(hash: strongSelf.stateHash, progress: 0.0, isPlaying: isPlaying)
                strongSelf.sendTrackId(trackId: previousTrackId, trackState: previousTrackState, completion: { [weak self] (error) in
                    guard let strongSelf = self, error == nil else { completion?(); return }

                    strongSelf.currentTrackId = previousTrackId
                    strongSelf.currentTrackState = previousTrackState
                    strongSelf.shouldStartPlay = isPlaying
                    strongSelf.prepareToPlay(track: previousTrack)
                    if isPlaying { strongSelf.player.play() }
                    completion?()
                })
            }
        }
    }

    // MARK: Notifications
    @objc func audioSessionInterrupted(_ notification: Notification) {
        print("interruption received: \(notification)")
    }

    @objc func playerItemDidPlayToEndTime(_ notification: Notification) {
        self.playForward()
    }

    @objc func audioSessionRouteChange(_ notification: Notification) {

        if let notificationUserInfo = notification.userInfo {
            if let audioSessionRouteChangeReason = AVAudioSessionRouteChangeReason(rawValue: notificationUserInfo[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0) {

                switch audioSessionRouteChangeReason {
                case .oldDeviceUnavailable:
                    if self.shouldStartPlay { DispatchQueue.main.async { self.player.play() } }
                default: break
                }
            }
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

    func observePlayerValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {

        if keyPath == #keyPath(Player.player.rate) {

            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayState: self.player.rate == 1.0)
            })

        } else if keyPath == #keyPath(Player.player.currentItem) {
            guard let currentTrack = self.currentTrack else { return }
            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItem: currentTrack)
            })
        } else if keyPath == #keyPath(Player.player.currentItem.status) {
            switch self.player.currentItem?.status {
            case .readyToPlay?: if (shouldStartPlay == true) { self.player.play() }
            default: break
            }
        } else if keyPath == #keyPath(Player.player.currentItem.duration) {
            guard let currentTrack = self.currentTrack else { return }
            self.observersContainer.invoke({ (observer) in
                observer.player(player: self, didChangePlayerItem: currentTrack)
            })
        }
    }


}

extension Player: WebSocketServiceObserver {

    func webSocketServiceDidDisconnect(_ service: WebSocketService) {
        self.updateStatus(status: .unknown)
    }

    func webSocketServiceDidConnect(_ service: WebSocketService) {
        self.updateStatus(status: .unknown)
    }

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) {

        switch self.status {
        case .unknown: self.playlist.reset(tracks: tracks)
        case .initialized: self.playlist.add(traks: tracks)
        case .failed: break
        }
    }

    func webSocketService(_ service: WebSocketService, didReceivePlayList playListItems: [String: PlayListItem]) {

        switch self.status {
        case .unknown:
                self.playlist.reset(playListItems: playListItems)
                if self.currentTrackId == nil,  let firstTrackId = self.playlist.firstTrackId {
                    self.prepareToPlay(trackId: firstTrackId)
                }

        case .initialized: self.playlist.add(playListItems: playListItems)
        case .failed: break
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId?) {

        if let trackId = trackId, self.currentTrackId?.id != trackId.id {
            self.currentTrackId = trackId
            self.prepareToPlay(trackId: trackId)
        }

        if trackId == nil && self.status == .unknown  {
            self.updateStatus(status: .initialized)

        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {

        print("time: \(Date().timeIntervalSince(self.isMasterStateSendDate))")
        guard Date().timeIntervalSince(self.isMasterStateSendDate) > 1.0 else { print("BadTime"); return }

        self.currentTrackState = trackState

        print("\(self.stateHash) == \(trackState)")

        if self.status == .unknown {
            self.updateStatus(status: .initialized)
        } else {
            if self.stateHash != trackState.hash {
                self.shouldStartPlay = false
                self.player.pause()
            }
        }

        self.updateCurrentTrackState(with: TimeInterval(trackState.progress))
    }
}

extension Player {

    func sendTrackId(trackId: TrackId, trackState: TrackState, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.setCurrentTrack(trackId: trackId)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(error); return }
            strongSelf.sendTrackState(trackState: trackState, completion: completion)
        }
    }

    func sendTrackState(trackState: TrackState, completion: ((Error?) -> ())? = nil) {
        let webSocketCommand = WebSocketCommand.setTrackState(trackState: trackState)
        self.webSocketService.sendCommand(command: webSocketCommand) { [weak self] (error) in
            guard let strongSelf = self, error == nil else { completion?(error); return }

            if strongSelf.isMaster == false {
                strongSelf.isMasterStateSendDate = Date()
            }

            completion?(nil)
        }

    }
}

extension Player {

    func setupMPRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] event in

            guard self?.status == .initialized else {
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

            guard self?.status == .initialized else {
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

            guard self?.status == .initialized else {
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

            guard self?.status == .initialized else {
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
        if let playerItem = self.player.currentItem {
            var nowPlayingInfo = [String : Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = self.currentTrack?.name
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

            // Set the metadata
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}

