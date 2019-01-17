//
//  LyricsKaraokeService.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 1/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


enum KaraokeViewMode: Int {
    case scroll
    case onePhrase
}

class LyricsKaraokeService {

    enum Mode {
        case none
        case lyrics
        case karaoke
    }

    private(set) var application: Application
    private(set) var player: Player

    var karaokeViewMode: KaraokeViewMode = .onePhrase
    
    let mode: BehaviorRelay<Mode> = BehaviorRelay(value: .none)
    let lyricsState: BehaviorRelay<LyricsState> = BehaviorRelay(value: .unknown)

    var karaokeAudioFileType: BehaviorRelay<AudioFileType> =  BehaviorRelay(value: .original)

    private(set) var tracksIdsLyrics = [Int : Lyrics]()

    let disposeBag = DisposeBag()

    init(with application: Application, player: Player) {

        self.application = application
        self.player = player

        let plyerCurrentItemChanges = self.player.currentItemObservable.asObservable()

        let modeChanges = self.mode.asObservable()

        let prefferedAudioFileTypeChanges = self.karaokeAudioFileType.asObservable()

        let lyricsStateChanges = self.lyricsState.asObservable()

        let _ = Observable.combineLatest(modeChanges, plyerCurrentItemChanges)
            .flatMap { [unowned self] (arg) -> Observable<LyricsState> in
                let (mode, playerItem) = arg
                return self.lyricsState(for: mode, playerItem: playerItem)
            }
            .subscribe(onNext: { (lyricsState) in
                self.lyricsState.accept(lyricsState)
            }, onError: { (error) in
                self.lyricsState.accept(.error(error))
            })
            .disposed(by: disposeBag)


        let _ = Observable.combineLatest(modeChanges, prefferedAudioFileTypeChanges, lyricsStateChanges)
            .subscribe(onNext: { [unowned self] (arg) in
                let (mode, audioFileType, lyricsState) = arg

                switch mode {
                case .none, .lyrics: self.player.setPreferredAudioFileType(preferredAudioFileType: .original)
                case .karaoke:
                    switch lyricsState {
                    case .lyrics(let lyrics):
                        guard lyrics.karaoke != nil else { self.player.setPreferredAudioFileType(preferredAudioFileType: .original); return }
                        self.player.setPreferredAudioFileType(preferredAudioFileType: audioFileType)
                    default: self.player.setPreferredAudioFileType(preferredAudioFileType: .original)
                    }
                }
            })
            .disposed(by: disposeBag)


        self.application.addWatcher(self)
    }

    func lyricsState(for mode: Mode, playerItem: PlayerItem?) -> Observable<LyricsState> {
        guard mode != .none else { return Observable<LyricsState>.just(.none) }
        guard let existingPlayerItem = playerItem ?? self.player.currentItem, self.shouldProccessLyrics(for: existingPlayerItem) == true else { return Observable<LyricsState>.just(.none) }
        guard let lyrics = self.tracksIdsLyrics[existingPlayerItem.playlistItem.track.id] else {
            return TrackRequest.lyricks(track: existingPlayerItem.playlistItem.track).rx
                .response(type: TrackResponse<Lyrics>.self)
                .do(onNext: { [weak self] (trackResponse) in
                    self?.tracksIdsLyrics[existingPlayerItem.playlistItem.track.id] = trackResponse.data
                })
                .map({ (trackResponse) -> LyricsState in
                    return .lyrics(trackResponse.data)
                })
                .asObservable()
        }


        return Observable<LyricsState>.just(.lyrics(lyrics))
    }

    func shouldProccessLyrics(for playerItem: PlayerItem) -> Bool {

        let playerItemTrack = playerItem.playlistItem.track

        var isCensorshipTrack = playerItemTrack.isCensorship
        if isCensorshipTrack == true, let user = self.application.user {
            isCensorshipTrack = user.stubTrackAudioFileReason(for: playerItemTrack) == .censorship
        }

        return isCensorshipTrack == false
            && playerItemTrack.isInstrumental == false
            && playerItemTrack.previewType != .noPreview
    }

}

extension LyricsKaraokeService {

    enum LyricsState: Equatable {
        case unknown
        case none
        case lyrics(Lyrics)
        case error(Error)

        static func ==(lhs: LyricsState, rhs: LyricsState) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown):
                return true

            case (.none, .none):
                return true

            case (.lyrics(let x), .lyrics(let y)):
                return x == y


            default: return false

            }
        }
    }
}

extension LyricsKaraokeService: ApplicationWatcher {

    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        guard let playerItem = self.player.currentItem, playerItem.playlistItem.track.isCensorship else { return }

        self.lyricsState(for: self.mode.value, playerItem: playerItem)
            .subscribe(onNext: { [unowned self] (lyricsState) in
                self.lyricsState.accept(lyricsState)
            }, onError: { [unowned self] (error) in
                self.lyricsState.accept(.error(error))
            })
            .disposed(by: disposeBag)

    }

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {

        guard let playerItem = self.player.currentItem, playerItem.playlistItem.track.id == trackForceToPlayState.trackId else { return }

        self.lyricsState(for: self.mode.value, playerItem: playerItem)
            .subscribe(onNext: { [unowned self] (lyricsState) in
                self.lyricsState.accept(lyricsState)
            }, onError: { [unowned self] (error) in
                self.lyricsState.accept(.error(error))
            })
            .disposed(by: disposeBag)
    }

}

