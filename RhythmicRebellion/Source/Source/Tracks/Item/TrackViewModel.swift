//
//  TrackViewModel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 1/9/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import DownloadButton

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
        return !(track.isFollowAllowFreeDownload || userHasPurchase)
    }
    
    var downloadState: Driver<PKDownloadButtonState> {
        
        let progress = dataState.asDriver().notNil().map { x -> PKDownloadButtonState in
            
            switch x {
            case .data(_):     return .downloaded
            case .progress(_): return .downloading
            case .error(_):    return .startDownload
            case .initialise:  return .pending
            }
            
        }
        
        return progress.startWith(.startDownload)
            .distinctUntilChanged()
        
    }
    
}

struct TrackViewModel : MVVM_ViewModel {
    
    let previewOptionViewModel: TrackPreviewOptionViewModel
    
    var isLockedForActions: Bool
    
    let track: Track
    let user: User?
    
    let isCurrentInPlayer: Bool
    let player: Player
    
    fileprivate let downloadTrigger: BehaviorSubject<Void?> = BehaviorSubject(value: nil)
    
    fileprivate let dataState: BehaviorRelay<DownloadStatus<URL>?> = BehaviorRelay(value: nil)
    
    fileprivate let downloadManager = MulticastDownloadManager.default
    
    init(router: TrackRouter, track: Track, user: User?,
         player: Player,
         textImageGenerator: TextImageGenerator, isCurrentInPlayer: Bool, isLockedForActions: Bool) {
        
        self.router = router
        self.track = track
        self.isCurrentInPlayer = isCurrentInPlayer
        self.user = user
        self.player = player
        
        self.previewOptionViewModel = TrackPreviewOptionViewModel.Factory().makeViewModel(track: track,
                                                                                          user: user,
                                                                                          player: player,
                                                                                          textImageGenerator: textImageGenerator)
        
        self.isLockedForActions = isLockedForActions
        
        let m = downloadManager
        m.downloadStatus(for: track.audioFile!.urlString)
            .bind(to: dataState)
            .disposed(by: bag)
        
        indicator.asDriver()
            .drive(onNext: { [weak h = router.owner] (loading) in
                h?.changedAnimationStatusTo(status: loading)
            })
            .disposed(by: bag)
        
    }
    
    let router: TrackRouter
    fileprivate let indicator: ViewIndicator = ViewIndicator()
    fileprivate let bag = DisposeBag()
    
}

extension TrackViewModel: Equatable {
    
    func download() {
        downloadManager.start(for: track.audioFile!.urlString)
    }
    
    func cancelDownload() {
        downloadManager.cancel(for: track.audioFile!.urlString)
    }
    
    func openIn(sourceRect: CGRect, sourceView: UIView) {
        
        guard let data = dataState.value,
              case .data(let url) = data else {
               return fatalErrorInDebug("Trying to `open in` track \(track.audioFile?.urlString) that hasn't been downloaded yet")
        }
        
        router.showOpenIn(url: url, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
    static func ==(lhs: TrackViewModel, rhs: TrackViewModel) -> Bool {
        return lhs.track == rhs.track &&
            lhs.isCurrentInPlayer == rhs.isCurrentInPlayer &&
            lhs.isPlaying == rhs.isPlaying &&
            lhs.isCensorship == rhs.isCensorship
    }
    
}
