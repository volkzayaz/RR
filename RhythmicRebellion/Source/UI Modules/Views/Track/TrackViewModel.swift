//
//  TrackItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/2/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

import DownloadButton

final class TrackAudioFileDownloadingProgress {

    var observer: NSKeyValueObservation?
    var callback: ((CGFloat) -> Void)?
}

extension TrackViewModel {
 
    var id: String { return String(track.id) }
    
    var title: String { return track.name }
    var description: String { return track.artist.name }
    
    var isPlayable: Bool { return track.isPlayable }
    
    var previewOptionImage: UIImage? { return previewOptionViewModel.image }
    var previewOptionHintText: String? { return previewOptionViewModel.hintText }
    
    var censorshipHintText: String? {
        guard self.isCensorship == true else { return nil }
        return NSLocalizedString("Contains explisit material", comment: "Contains explisit material hint text")
    }
    
    var downloadHintText: String? {
        
        let userHasPurchase = user?.hasPurchase(for: track) ?? false
        
        guard track.isFollowAllowFreeDownload || userHasPurchase else {
            return nil
        }
        
        if user?.isGuest ?? true { return R.string.localizable.freeDownloadForFans() }
        
        return R.string.localizable.freeDownloadForFollowers()
        
    }
    
    var isPlaying: Bool {
        return isCurrentInPlayer && player.isPlaying
    }

    var isCensorship: Bool {
        return user?.isCensorshipTrack(track) ?? track.isCensorship
    }
    
    
    var downloadPercent: Driver<CGFloat> {
        return dataState.asDriver().map { x -> CGFloat? in
            guard let state = x,
                  case .progress(let p) = state else {
                    return nil
            }
            
            return CGFloat(p)
        }
        .notNil()
    }
    
    var downloadDisabled: Bool {
        let userHasPurchase = user?.hasPurchase(for: track) ?? false
        return track.isFollowAllowFreeDownload || userHasPurchase
    }
    
    var downloadState: Driver<PKDownloadButtonState> {
        
        let pending = token.asDriver(onErrorJustReturn: nil)
            .map { $0 == nil ? .startDownload : PKDownloadButtonState.pending }
        
        let progress = dataState.asDriver().notNil().map { x -> PKDownloadButtonState in
            
            switch x {
            case .data(_):     return .downloaded
            case .progress(_): return .downloading
            }
            
        }
        
        return Driver.merge([pending, progress])
            .distinctUntilChanged()
        
    }
    
}

struct TrackViewModel {
    
    let previewOptionViewModel: TrackPreviewOptionViewModel

    var isLockedForActions: Bool

    let track: Track
    let user: User?
    
    let isCurrentInPlayer: Bool
    let player: Player
    
    fileprivate let downloadTrigger: BehaviorSubject<Void?> = BehaviorSubject(value: nil)
    
    fileprivate let token: BehaviorSubject<DownloadToken?> = BehaviorSubject(value: nil)
    fileprivate let dataState: BehaviorRelay<ChunkedData<URL>?> = BehaviorRelay(value: nil)
    
    init(track: Track, user: User?,
         player: Player, audioFileLocalStorageService: AudioFileLocalStorageService?,
         textImageGenerator: TextImageGenerator, isCurrentInPlayer: Bool, isLockedForActions: Bool) {

        self.track = track
        self.isCurrentInPlayer = isCurrentInPlayer
        self.user = user
        self.player = player
        
        self.previewOptionViewModel = TrackPreviewOptionViewModel.Factory().makeViewModel(track: track,
                                                                                          user: user,
                                                                                          player: player,
                                                                                          textImageGenerator: textImageGenerator)

        self.isLockedForActions = isLockedForActions
        
        downloadTrigger.asObservable().notNil().map {
                return DownloadManager.default.download(x: track.audioFile!.urlString)
            }
            .flatMapLatest { [weak t = token] input -> Observable<ChunkedData<URL>> in
                
                let newToken = input.1
                t?.unsafeValue?.cancel()
                t?.onNext(newToken)
                
                return input.0.silentCatch()
            }
            .bind(to: dataState)
            .disposed(by: bag)
        
    }
    
    fileprivate let bag = DisposeBag()
}

extension TrackViewModel: Equatable {
    
    func download() {
        downloadTrigger.onNext( () )
    }
    
    func cancelDownload() {
        token.unsafeValue?.cancel()
        token.onNext(nil)
    }
    
    static func ==(lhs: TrackViewModel, rhs: TrackViewModel) -> Bool {
        return lhs.track == rhs.track &&
            lhs.isCurrentInPlayer == rhs.isCurrentInPlayer &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.isCensorship == rhs.isCensorship
    }
    
}
