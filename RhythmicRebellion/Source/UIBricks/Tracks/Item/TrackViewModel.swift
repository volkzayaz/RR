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
        
        let option = TrackPreviewOptionViewModel(type: .init(with: track,
                                                             user: user,
                                                             μSecondsPlayed: nil),
                                                 textImageGenerator: textImageGenerator)
        
        guard case .fullLimitTimes = option.type else {
            return .just(option)
        }
        
        let u = user
        let t = track
        let g = textImageGenerator
        
        return appState.map { $0.player.tracks.previewTime[t.id] }
            .distinctUntilChanged()
            .map { time in
                
                return TrackPreviewOptionViewModel(type: .init(with: t,
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
        
        let userHasPurchase = user.hasPurchase(for: track)
        
        guard track.isFollowAllowFreeDownload || userHasPurchase else {
            return nil
        }
        
        if user.isGuest { return R.string.localizable.freeDownloadForFans() }
        
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
        return user.isCensorshipTrack(track)
    }
    
    var downloadEnabled: Bool {
        if user.hasPurchase(for: track) {
            return true
        }
        
        if user.isFollower(for: track.artist.id) && track.isFollowAllowFreeDownload {
            return true
        }
        
        return false
    }
    
}

struct TrackViewModel : MVVM_ViewModel, IdentifiableType {
    
    var identity: String {
        return trackProvidable.identity
    }
    
    var track: Track {
        return trackProvidable.track
    }
    let trackProvidable: TrackProvidable
    let user: User
    
    fileprivate let downloadTrigger: BehaviorSubject<Void?> = BehaviorSubject(value: nil)
    
    let downloadViewModel: DownloadViewModel?
    private let textImageGenerator = TextImageGenerator(font: UIFont.systemFont(ofSize: 8.0))
    
    let actions: AlertActionsViewModel<ActionViewModel>
    
    init(router: TrackRouter,
         trackProvidable: TrackProvidable,
         user: User,
         actions: AlertActionsViewModel<ActionViewModel>) {
        
        self.router = router
        self.trackProvidable = trackProvidable
        self.user = user
        self.actions = actions
        
        if let url = trackProvidable.track.audioFile?.urlString {
            downloadViewModel = DownloadViewModel(remoteURL: url)
        }
        else {
            downloadViewModel = nil
        }
        
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

extension TrackViewModel {
    
    func openIn(sourceRect: CGRect, sourceView: UIView) {
        
        guard let data = downloadViewModel?.dataState.value,
              case .data(let url) = data else {
               return fatalErrorInDebug("Trying to `open in` track \(track.audioFile!.urlString) that hasn't been downloaded yet")
        }
        
        router.showOpenIn(url: url, sourceRect: sourceRect, sourceView: sourceView)
        
    }
    
    func presentActions(sourceRect: CGRect,
                        sourceView: UIView) {
        
        router.present(actions: actions,
                       sourceRect: sourceRect,
                       sourceView: sourceView)
        
    }
    
    func showTip(tip: String, view: UIView, superView: UIView) {
        router.showTip(text: tip, view: view, superView: superView)
    }
    
}

extension TrackViewModel: Equatable {
    
    static func ==(lhs: TrackViewModel, rhs: TrackViewModel) -> Bool {
        return lhs.track == rhs.track &&
            lhs.isCensorship == rhs.isCensorship &&
            ///TODO: compare only user items that are reflected in the UI (follow, listening progress)
            ///for example we don't care if user changed email for displaying track
            lhs.user == rhs.user
    }
    
}
