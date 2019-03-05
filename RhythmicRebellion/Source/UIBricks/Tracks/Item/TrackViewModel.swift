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
import RxDataSources

import DownloadButton

extension TrackViewModel {
    
    var id: String { return String(track.id) }
    
    var title: String { return track.name }
    var description: String { return track.artist.name }
    
    var isPlayable: Bool { return track.isPlayable }
    
    var previewOptionImage: Driver<UIImage?> {
        return previewOption.map { $0?.image }
    }
    
    var previewOptionHintText: Driver<String?> {
        return previewOption.map { $0?.hintText }
    }
    
    fileprivate var previewOption: Driver<TrackPreviewOptionViewModel?> {
        
        guard case .full? = track.previewType else {
            return .just(TrackPreviewOptionViewModel(previewOptionType: .init(with: track,
                                                                              user: user, μSecondsPlayed: nil),
                                                     textImageGenerator: textImageGenerator))
        }
        
        let u = user
        let t = track
        let g = textImageGenerator
        
        return appState.map { $0.player.tracks.previewTime[t.id] }
            .distinctUntilChanged()
            .map { time in
                
                return TrackPreviewOptionViewModel(previewOptionType: .init(with: t,
                                                                            user: u,
                                                                            μSecondsPlayed: time),
                                                   textImageGenerator: g)
                
        }
        
    }
    
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
    
    var isPlaying: Driver<Bool> {
        return appState.map { $0.player.currentItem?.state.isPlaying ?? false }
                       .distinctUntilChanged()
    }
    
    var equalizerHidden: Driver<Bool> {
        
        let t = trackProvidable
        return appState.map { $0.currentTrack }
            .distinctUntilChanged()
            .map { x in
                guard let x = x else { return true }
            
                return !t.isEqualTo(orderedTrack: x)
            }
        
    }
    
    var isCensorship: Bool {
        return user?.isCensorshipTrack(track) ?? track.isCensorship
    }
    
    var downloadDisabled: Bool {
        let userHasPurchase = user?.hasPurchase(for: track) ?? false
        return !(track.isFollowAllowFreeDownload || userHasPurchase)
    }
    
}

struct TrackViewModel : MVVM_ViewModel, IdentifiableType {
    
    var identity: String {
        return trackProvidable.identity
    }
    
    var track: Track {
        return trackProvidable.track
    }
    fileprivate let trackProvidable: TrackProvidable
    let user: User?
    
    fileprivate let downloadTrigger: BehaviorSubject<Void?> = BehaviorSubject(value: nil)
    
    let downloadViewModel: DownloadViewModel
    let textImageGenerator: TextImageGenerator
    
    init(router: TrackRouter, trackProvidable: TrackProvidable, user: User?,
         textImageGenerator: TextImageGenerator) {
        
        self.router = router
        self.trackProvidable = trackProvidable
        self.user = user
    
        self.textImageGenerator = textImageGenerator
        
        downloadViewModel = DownloadViewModel(remoteURL: trackProvidable.track.audioFile!.urlString)
        
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
    
    func openIn(sourceRect: CGRect, sourceView: UIView) {
        
        guard let data = downloadViewModel.dataState.value,
              case .data(let url) = data else {
               return fatalErrorInDebug("Trying to `open in` track \(track.audioFile!.urlString) that hasn't been downloaded yet")
        }
        
        router.showOpenIn(url: url, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
    static func ==(lhs: TrackViewModel, rhs: TrackViewModel) -> Bool {
        return lhs.track == rhs.track &&
            lhs.isCensorship == rhs.isCensorship
    }
    
}
