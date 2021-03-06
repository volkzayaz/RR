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
    
    var index: String { return "\(trackRepresentation.index + 1)" }
    var artwork: String { return track.images.first?.simpleURL ?? "" }

    var indexHidden: Bool {
        return mode == .artwork
    }
    
    var artworkHidden: Bool {
        return mode == .index
    }
    
    var equalizerBackgroundColor: UIColor {
        return artworkHidden ? .clear : .equalizerBackground
    }
    
    var isPlaying: Driver<Bool> {
        return appState.map { $0.player.currentItem?.state.isPlaying ?? false }
                       .distinctUntilChanged()
    }
    
    var equalizerHidden: Driver<Bool> {
        
        let t = trackRepresentation
        return appState.map { $0.currentTrack }
            .distinctUntilChanged()
            .map { x in
                guard let x = x else { return true }
            
                return !t.providable.isSame(with: x)
            }
        
    }
    
    enum Attribute {
        case explicitMaterial
        case downloadEnabled
        case raw(String)
    }
    
    var attributes: Driver<[Attribute]> {
        
        var x: [Attribute] = []
        
        if !track.isPlayable {
            return .just([ .raw("  SOON  ") ])
        }
        
        if track.isCensorship {
            x.append(.explicitMaterial)
        }
        
        if user.hasPurchase(for: track) ||
           (user.isFollower(for: track.artist.id) && track.isFollowAllowFreeDownload) {
            x.append(.downloadEnabled)
        }
        
        if case .limit45? = track.previewType {
            x.append( .raw(" 45 SEC ") )
            return .just(x)
        }
        else if case .limit45? = track.previewType {
            x.append( .raw(" 90 SEC ") )
            return .just(x)
        }
        else if case .full? = track.previewType {
            
            let u = user
            let t = track
            
            return appState.map { $0.player.tracks.previewTime[t.id] }
                .distinctUntilChanged()
                .map { time in
                    
                    let z = TrackPreviewOptionViewModel(type: .init(with: t,
                                                                    user: u,
                                                                    μSecondsPlayed: time))
                    
                    if case .fullLimitTimes(let previewTimes) = z.type {
                        x.append(.raw("   X\(previewTimes)   "))
                    }
                    
                    return x
                }
        }
        
        return .just(x)
    }
    
    var track: Track {
        return trackRepresentation.track
    }
    
}

struct TrackViewModel : MVVM_ViewModel, IdentifiableType {
    
    let trackRepresentation: TrackRepresentation
    let user: User
    let actions: [RRSheet.Action]
    let mode: ThumbMode
    
    let downloadViewModel: DownloadViewModel?
    
    fileprivate let downloadTrigger: BehaviorSubject<Void?> = BehaviorSubject(value: nil)
    
    init(router: TrackRouter,
         trackRepresentation: TrackRepresentation,
         mode: ThumbMode,
         user: User,
         actions: [RRSheet.Action]) {
        
        self.router = router
        self.trackRepresentation = trackRepresentation
        self.mode = mode
        self.user = user
        self.actions = actions
        
        if let _ = trackRepresentation.track.audioFile?.urlString {
            downloadViewModel = DownloadViewModel(downloadable: trackRepresentation.track)
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
 
    var identity: String {
        return trackRepresentation.identity
    }
    
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
    
}

extension TrackViewModel: Equatable {
    
    static func ==(lhs: TrackViewModel, rhs: TrackViewModel) -> Bool {
        return lhs.track == rhs.track &&
            ///TODO: compare only user items that are reflected in the UI (follow, listening progress)
            ///for example we don't care if user changed email for displaying track
            lhs.user == rhs.user
    }
    
}
