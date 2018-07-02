//
//  PlayerControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import AVFoundation
import MediaPlayer

private var playerKVOContext = 0

final class PlayerControllerViewModel: NSObject, PlayerViewModel {

    // MARK: - Public properties -
    var playerItemDuration: TimeInterval? {
        guard let duration = self.player.currentItem?.duration, duration.value != 0 else { return nil }
        return TimeInterval(CMTimeGetSeconds(duration))
    }

    var playerItemDurationString: String {
        guard let playerItemDuration = self.playerItemDuration else { return "--:--"}

        return playerItemDuration.stringFormatted();
    }

    var playerItemCurrentTime: TimeInterval? {
        if self.player.rate == 1.0 {
            let currentTime = self.player.currentTime()
            guard currentTime.value != 0 else { return nil }
            return TimeInterval(CMTimeGetSeconds(currentTime))
        } else if let currentTrackState = self.currentTrackState  {
            return currentTrackState.progress
        }

        return nil
    }

    var playerItemCurrentTimeString: String {
        guard let playerItemCurrentTime = self.playerItemCurrentTime else { return "--:--"}

        return playerItemCurrentTime.stringFormatted();
    }

    var playerItemProgress: Float {
        guard let playerItemDuration = self.playerItemDuration, playerItemDuration != 0.0,
            let playerItemCurrentTime = self.playerItemCurrentTime else { return 0.0 }

        return Float(playerItemCurrentTime / playerItemDuration)
    }

    var isPlaying: Bool {
        return self.player.rate == 1.0 || self.currentTrackState?.isPlaying ?? false == true
    }

    // MARK: - Private properties -

    private(set) weak var delegate: PlayerViewModelDelegate?
    private(set) weak var router: PlayerRouter?

//    private let webSocketToken = "32707f7e47c587a369fbbe3ed123beaa512438a068042c7f3a3f06a0bd1f937c"
//    private let webSocketToken = "f8b5cb700eb684b075d03867019359a0581fe459b4b33673441a2917464929dc"  //Alena

//    private let webSocketToken = "f4dd23e815bb3ece8da32f4b4d4f9dc8d12776ae47a7ce0871db086a49b82744"
//    private let webSocketToken = "f3b77ecd0889aecfdddf31dd7d108a28db4e3303400413bef9a93175f0eddb1b"

    private(set) var webSocketService: WebSocketService

    private(set) var tracks = [Track]()
    private(set) var playList = [String : PlayListItem]()
    private(set) var currentTrackId: TrackId?
    private(set) var currentTrack: Track?
    private(set) var currentTrackState: TrackState?

    @objc private var player = AVPlayer()
    var timeObserverToken: Any?
    var shouldStartPlay: Bool = false

    // MARK: - Lifecycle -

    init(router: PlayerRouter, webSocketService: WebSocketService) {
        self.router = router
        self.webSocketService = webSocketService

        super.init()

        self.webSocketService.addObserver(self)
    }

    deinit {
        self.webSocketService.removeObserver(self)
    }

    func load(with delegate: PlayerViewModelDelegate) {
        self.delegate = delegate

        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionInterrupted(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            let _ = try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("an error occurred when audio session category.\n \(error)")
        }

        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.player.rate == 0.0 {
                self.player.play()

//                self.webSocketService.connect(with: self.webSocketToken)

                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.player.rate == 1.0 {
                self.player.pause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in

            guard let playItemURL = URL(string: "http://www.hochmuth.com/mp3/Beethoven_12_Variation.mp3") else { return .commandFailed}
            let playerItem = AVPlayerItem(url: playItemURL)

            if self.player.currentItem != playerItem {
                self.player.replaceCurrentItem(with: playerItem)
            }

            return .success
        }

//        self.webSocketService.connect(with: webSocketToken)
    }

    func startObservePlayer() {

        addObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.rate), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem.status), options: [.new, .initial], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem.duration), options: [.new, .initial], context: &playerKVOContext)

        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
//            print("timeElapsed: \(timeElapsed)")
            self.delegate?.refreshProgressUI()


            if let playerItem = self.player.currentItem {
                var nowPlayingInfo = [String : Any]()
                nowPlayingInfo[MPMediaItemPropertyTitle] = "Haydn_Cello_Concerto_D-1.mp3"
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate

                // Set the metadata
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }

    }

    func stopObservePlayer() {

        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        removeObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.rate), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem.status), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerControllerViewModel.player.currentItem.duration), context: &playerKVOContext)
    }

    func playerItemDescriptionAttributedText(for traitCollection: UITraitCollection) -> NSAttributedString {
        guard let currentTrack = self.currentTrack else { return NSAttributedString() }

        let currentTrackArtistName = currentTrack.artist.name + (traitCollection.horizontalSizeClass == .regular ?  "\n" : " - ")
        let descriptionAttributedString = NSMutableAttributedString(string: currentTrackArtistName,
                                                                    attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 0.760392487, green: 0.7985035777, blue: 0.9999999404, alpha: 0.96),
                                                                                 NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)])

        descriptionAttributedString.append(NSAttributedString(string: currentTrack.name,
                                                              attributes: [NSAttributedStringKey.foregroundColor : #colorLiteral(red: 1, green: 0.3639442921, blue: 0.7127844095, alpha: 0.96),
                                                                           NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12.0)]))

        return descriptionAttributedString
    }

    func prepareToPlay(trackId: TrackId) {

        guard let track = self.tracks.filter({ return $0.id == trackId.id }).first else { return }

        self.currentTrackId = trackId
        self.prepareToPlay(track: track)
    }

    func prepareToPlay(track: Track) {

        self.currentTrack = track

        guard let audioFile = track.audioFile, let playItemURL = URL(string: audioFile.urlString) else { return }
        let playerItem = AVPlayerItem(url: playItemURL)

        if self.player.currentItem != playerItem {
            self.player.replaceCurrentItem(with: playerItem)
        }

        self.currentTrackState = nil
    }

    // MARK: - Actions -

    func play() {
        if self.player.currentItem == nil {

        } else if let currentTrackState = self.currentTrackState {

            let time = CMTime(seconds: Double(currentTrackState.progress), preferredTimescale: Int32(kCMTimeMaxTimescale))
            self.player.currentItem?.seek(to: time, completionHandler: { [unowned self] (success) in
                guard success == true else { return }
                self.player.play()
            })
        } else {
            self.player.play()
        }

        self.shouldStartPlay = true
    }

    func pause() {
        self.player.pause()
        self.shouldStartPlay = false
    }

    func forward() {
        guard let currentTrackId = self.currentTrackId, let currentPlayListItem = self.playList[currentTrackId.key] else { return }

        var trackId = currentTrackId
        var track = self.currentTrack
        var playListItem = currentPlayListItem
        repeat {
            if let nextTrackKey = playListItem.nextTrackKey {
                if let nextPlayListItem = self.playList[nextTrackKey] {
                    playListItem = nextPlayListItem
                    trackId = TrackId(id: playListItem.id, key: playListItem.trackKey)
                    track = self.tracks.filter({ return $0.id == playListItem.id }).first
                } else {
                    break
                }
            } else if let firstTrack = self.playList.filter( { return $0.value.previousTrackKey == nil }).first {
                playListItem = firstTrack.value
                trackId = TrackId(id: playListItem.id, key: playListItem.trackKey)
                track = self.tracks.filter({ return $0.id == playListItem.id }).first
            }

        } while track?.isPlayable == false

        self.currentTrackId = trackId
        self.prepareToPlay(track: track!)

    }

    func backward() {

        if self.playerItemCurrentTime ?? TimeInterval(0.0) > TimeInterval(3.0) {
            let time = CMTime(seconds: Double(0.0), preferredTimescale: Int32(kCMTimeMaxTimescale))
            self.player.currentItem?.seek(to: time, completionHandler: { [unowned self] (success) in
                guard success == true else { return }
                self.currentTrackState = nil
                self.delegate?.refreshProgressUI()
            })
            return
        }

        guard let currentTrackId = self.currentTrackId, let currentPlayListItem = self.playList[currentTrackId.key] else { return }

        var trackId = currentTrackId
        var track = self.currentTrack
        var playListItem = currentPlayListItem
        repeat {
            if let prevTrackKey = playListItem.previousTrackKey {
                if let prevPlayListItem = self.playList[prevTrackKey] {
                    playListItem = prevPlayListItem
                    trackId = TrackId(id: playListItem.id, key: playListItem.trackKey)
                    track = self.tracks.filter({ return $0.id == playListItem.id }).first
                } else {
                    break
                }
            } else if let lastTrack = self.playList.filter( { return $0.value.nextTrackKey == nil }).first {
                playListItem = lastTrack.value
                trackId = TrackId(id: playListItem.id, key: playListItem.trackKey)
                track = self.tracks.filter({ return $0.id == playListItem.id }).first
            }

        } while track?.isPlayable == false

        self.currentTrackId = trackId
        self.prepareToPlay(track: track!)
    }
    

    // MARK: - KVO Observation -

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        // Update our UI when player or `player.currentItem` changes.
        if context == &playerKVOContext {
            self.observePlayerValue(forKeyPath: keyPath, of: object, change: change)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func observePlayerValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {

        if keyPath == #keyPath(PlayerControllerViewModel.player.rate) {
            self.delegate?.refreshUI()
        } else if keyPath == #keyPath(PlayerControllerViewModel.player.currentItem) {
            self.delegate?.refreshUI()
        } else if keyPath == #keyPath(PlayerControllerViewModel.player.currentItem.status) {
            switch self.player.currentItem?.status {
            case .readyToPlay?: if (shouldStartPlay == true) { self.player.play() }
            default: break
            }
        } else if keyPath == #keyPath(PlayerControllerViewModel.player.currentItem.duration) {
            self.delegate?.refreshUI()
        }
    }

    // MARK: - Notifications -
    @objc func audioSessionInterrupted(_ notification:Notification) {
        print("interruption received: \(notification)")
    }

}

extension PlayerControllerViewModel: WebSocketServiceObserver {

    func webSocketService(_ service: WebSocketService, didReceiveTracks tracks: [Track]) {
        self.tracks = tracks
    }

    func webSocketService(_ service: WebSocketService, didReceivePlayList playList: [String: PlayListItem]) {
        self.playList = playList

        if let firstTrack = self.playList.filter( { return $0.value.previousTrackKey == nil }).first {
            self.prepareToPlay(trackId: TrackId(id: firstTrack.value.id, key: firstTrack.value.trackKey))
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackId trackId: TrackId) {
        self.currentTrackId = trackId

        if let track = self.tracks.filter({ return $0.id == trackId.id }).first {
            self.prepareToPlay(track: track)
        }
    }

    func webSocketService(_ service: WebSocketService, didReceiveCurrentTrackState trackState: TrackState) {
        self.currentTrackState = trackState
        self.delegate?.refreshProgressUI()
    }
}

