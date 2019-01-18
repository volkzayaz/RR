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

    let explicitMaterialExcluded: BehaviorRelay<Bool>
    let forceToPlayTracksIds: BehaviorRelay<Set<Int>>

    var karaokeAudioFileType: BehaviorRelay<AudioFileType> =  BehaviorRelay(value: .original)

    private(set) var tracksIdsLyrics = [Int : Lyrics]()

    let disposeBag = DisposeBag()

    deinit {
        self.application.removeWatcher(self)
    }

    init(with application: Application, player: Player) {

        self.application = application
        self.player = player

        let user = self.application.user as? FanUser

        self.explicitMaterialExcluded = BehaviorRelay(value: user?.profile.listeningSettings.isExplicitMaterialExcluded ?? true)
        self.forceToPlayTracksIds = BehaviorRelay(value: user?.profile.forceToPlay ?? Set<Int>())

        let plyerCurrentItemChanges = self.player.currentItemObservable.asObservable()
        let modeChanges = self.mode.asObservable()

        let prefferedAudioFileTypeChanges = self.karaokeAudioFileType.asObservable()
        let lyricsStateChanges = self.lyricsState.asObservable()

        let explicitMaterialExcludedChanges = self.explicitMaterialExcluded.asObservable()
        let forceToPlayTracksIdsChanges = self.forceToPlayTracksIds.asObservable()

        let _ = Observable.combineLatest(modeChanges, plyerCurrentItemChanges, explicitMaterialExcludedChanges, forceToPlayTracksIdsChanges)
            .flatMap { [unowned self] (args) -> Observable<LyricsState> in
                let (mode, playerItem, explicitMaterialExcluded, forceToPlayTracksIds) = args

                guard mode != .none else { return Observable<LyricsState>.just(.none) }
                guard let track = playerItem?.playlistItem.track else { return Observable<LyricsState>.just(.none) }

                if track.isCensorship == true, explicitMaterialExcluded == true, forceToPlayTracksIds.contains(track.id) == false {
                    return Observable<LyricsState>.just(.none)
                }

                guard let lyrics = self.tracksIdsLyrics[track.id] else {
                    return TrackRequest.lyricks(track: track).rx
                        .response(type: TrackResponse<Lyrics>.self)
                        .do(onNext: { [weak self, trackId = track.id] (trackResponse) in
//                            self?.tracksIdsLyrics[trackId] = trackResponse.data
                        })
                        .map({ (trackResponse) -> LyricsState in
                            return .lyrics(trackResponse.data)
                        })
                        .asObservable()
                        .catchError({ (error) -> Observable<LyricsKaraokeService.LyricsState> in
                            return Observable<LyricsState>.just(.error(error))
                        })
                }
                return Observable<LyricsState>.just(.lyrics(lyrics))
            }
            .subscribe(onNext: { (lyricsState) in
                self.lyricsState.accept(lyricsState)
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
}

extension LyricsKaraokeService {

    enum LyricsState: Equatable {
        case unknown
        case none
        case lyrics(Lyrics)
        case error(Error)

        var isError: Bool {
            switch self {
            case .error( _ ): return true
            default: return false
            }
        }

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
        self.explicitMaterialExcluded.accept(listeningSettings.isExplicitMaterialExcluded)
    }

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {
        self.forceToPlayTracksIds.accept(Set<Int>(forceToPlayTracksIds))
    }

    func application(_ application: Application, didChange user: User) {

        let fanUser = self.application.user as? FanUser

        self.explicitMaterialExcluded.accept(fanUser?.profile.listeningSettings.isExplicitMaterialExcluded ?? true)
        self.forceToPlayTracksIds.accept(fanUser?.profile.forceToPlay ?? Set<Int>())
    }
}

