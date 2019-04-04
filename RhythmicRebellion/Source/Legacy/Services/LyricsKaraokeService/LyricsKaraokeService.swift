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
    
    public enum AudioFileType: UInt {
        case original
        case backing
        case clean
    }

    private(set) var application: Application
    
    var karaokeViewMode: KaraokeViewMode = .onePhrase
    
    let mode: BehaviorRelay<Mode> = BehaviorRelay(value: .none)
    let lyricsState: BehaviorRelay<LyricsState> = BehaviorRelay(value: .unknown)

    let explicitMaterialExcluded: BehaviorRelay<Bool>
    let forceToPlayTracksIds: BehaviorRelay<Set<Int>>

    var karaokeAudioFileType: BehaviorRelay<AudioFileType> =  BehaviorRelay(value: .original)

    private var isPlaying = BehaviorRelay(value: false)
    var isIdleTimerDisabled: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    private var disableIdleTimerSubscription: Disposable? {
        willSet {
            disableIdleTimerSubscription?.dispose()
        }
    }


    private(set) var tracksIdsLyrics = [Int : Lyrics]()

    let disposeBag = DisposeBag()

    deinit {
        
    }

    init(with application: Application) {

        self.application = application
        
        let user = appStateSlice.user

        self.explicitMaterialExcluded = BehaviorRelay(value: user.profile.listeningSettings.isExplicitMaterialExcluded ?? true)
        self.forceToPlayTracksIds = BehaviorRelay(value: user.profile.forceToPlay ?? Set<Int>())

        //let plyerCurrentItemChanges = self.player.currentItemObservable.asObservable()
        let modeChanges = self.mode.asObservable()

        let prefferedAudioFileTypeChanges = self.karaokeAudioFileType.asObservable()
        let lyricsStateChanges = self.lyricsState.asObservable()

        let explicitMaterialExcludedChanges = self.explicitMaterialExcluded.asObservable()
        let forceToPlayTracksIdsChanges = self.forceToPlayTracksIds.asObservable()

        //self.isPlaying = BehaviorRelay(value: self.player.isPlaying)

        let _ = Observable.combineLatest(modeChanges,
                                         //plyerCurrentItemChanges,
                                         explicitMaterialExcludedChanges, forceToPlayTracksIdsChanges)
            .flatMap { [unowned self] (args) -> Observable<LyricsState> in
                let (mode,
                    //playerItem,
                        explicitMaterialExcluded, forceToPlayTracksIds) = args

                return Observable<LyricsState>.just(.none)
                
                guard mode != .none,
                      let track = playerItem?.playlistItem.track,
                      track.isPlayable == true, track.isInstrumental == false,
                      track.isCensorship == false, explicitMaterialExcluded == false,
                      forceToPlayTracksIds.contains(track.id) == true  else {
                    return .just(.none)
                }
                
                return TrackRequest.lyrics(track: track).rx
                    .response(type: BaseReponse<Lyrics>.self)
                    .map { .lyrics($0.data) }
                    .asObservable()
                    .catchError({ (error) -> Observable<LyricsKaraokeService.LyricsState> in
                        return Observable<LyricsState>.just(.error(error))
                    })
                
            }
            .bind(to: lyricsState)
            .disposed(by: disposeBag)


        let _ = Observable.combineLatest(modeChanges, prefferedAudioFileTypeChanges, lyricsStateChanges)
            .subscribe(onNext: { [unowned self] (arg) in
                let (mode, audioFileType, lyricsState) = arg

                switch mode {
                case .none, .lyrics: break; //self.player.setPreferredAudioFileType(preferredAudioFileType: .original)
                case .karaoke:
                    switch lyricsState {
                    case .lyrics(let lyrics):
                        guard lyrics.karaoke != nil else {
                            //self.player.setPreferredAudioFileType(preferredAudioFileType: .original)
                            return
                        }
                        //self.player.setPreferredAudioFileType(preferredAudioFileType: audioFileType)
                        
                    default: break; // self.player.setPreferredAudioFileType(preferredAudioFileType: .original)
                    }
                }
            })
            .disposed(by: disposeBag)

        _ = Observable.combineLatest(isPlaying.asObservable(), isIdleTimerDisabled.asObservable())
            .subscribe(onNext: { [unowned self] (arg) in
                let (isPlaying, isIdleTimerDisabled) = arg

                guard isPlaying == true, isIdleTimerDisabled == true else {
                    self.disableIdleTimerSubscription = nil
                    return
                }

                self.disableIdleTimerSubscription = self.application.disableIdleTimerSubscription.subscribe()
            })
            .disposed(by: disposeBag)


        
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

extension LyricsKaraokeService {

    func player(didChangePlayState isPlaying: Bool) {
        self.isPlaying.accept(isPlaying)
    }

}

extension LyricsKaraokeService {

    func application(_ application: Application, didChangeUserProfile listeningSettings: ListeningSettings) {
        self.explicitMaterialExcluded.accept(listeningSettings.isExplicitMaterialExcluded)
    }

    func application(_ application: Application, didChangeUserProfile forceToPlayTracksIds: [Int], with trackForceToPlayState: TrackForceToPlayState) {
        self.forceToPlayTracksIds.accept(Set<Int>(forceToPlayTracksIds))
    }

    func application(_ application: Application, didChange user: User) {

        let fanUser = appStateSlice.user

        self.explicitMaterialExcluded.accept(fanUser?.profile.listeningSettings.isExplicitMaterialExcluded ?? true)
        self.forceToPlayTracksIds.accept(fanUser?.profile.forceToPlay ?? Set<Int>())
    }
}

