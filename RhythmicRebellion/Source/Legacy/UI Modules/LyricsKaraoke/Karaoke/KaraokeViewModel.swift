//
//  KaraokeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import RxSwift
import RxCocoa

extension KaraokeViewModel {
    
    var mode: Driver<PlayerState.Lyrics.Mode.KaraokeConfig.Mode> {
        return appState.map { state -> PlayerState.Lyrics.Mode.KaraokeConfig.Mode? in
            guard case .karaoke(let config)? = state.player.currentItem?.lyrics?.mode else {
                return nil
            }
            
            return config.mode
        }
        .notNil()
    }
    
    var vocalButtonSelected: Driver<Bool> {
        return appState.map { state -> Bool in
            guard case .karaoke(let config)? = state.player.currentItem?.lyrics?.mode else {
                return false
            }
            
            return config.track == .vocal
        }
    }
    
    var canChangeAudioFileType: Driver<Bool> {
        return appState.map { state in
            return state.player.currentItem?.lyrics?.data.karaoke != nil
//                && self.player.currentItem.state.blocked == false
//                && self.player.currentItem.state.waitingAddons == false
//                && self.player.currentQueueItem?.isTrack == true

        }
    }
    
    var karaokeChanges: Driver<Karaoke?> {
        
        return appState.map { $0.player.currentItem?.lyrics?.data.karaoke }
            .distinctUntilChanged()
            .do(onNext: { [weak self] (k) in
                self?.karaoke = k
            })
        
    }
    
    var currentIndexPathChanges: Driver<IndexPath?> {

        ///TODO: this reaction depended on isBlocked state. Find out why
        
        return appState.map { state in
            
            guard let intervals = state.player.currentItem?.lyrics?.data.karaoke?.intervals,
                  let progress = state.player.currentItem?.state.progress else {
                return nil
            }
         
            ////WTF is going on here?
            
            if let intervalIndex = intervals.firstIndex(where: { $0.range.contains(progress) }) {
                return IndexPath(item: intervalIndex, section: 0)
            }
            
            if let previousIntervalIndex = intervals.firstIndex(where: { (interval) -> Bool in
                return interval.range.lowerBound > progress
            }) {
                return IndexPath(item: max(0, previousIntervalIndex - 1), section: 0)
            }
            
            return nil
            
        }
            .do(onNext: { [weak self] (ip) in
                self?.currentItemIndexPath = ip
            })
        
    }
    
    var thumbnailURL: Driver<URL?> {
        return appState.map { $0.currentTrack?.track }
            .distinctUntilChanged()
            .map { $0?.thumbnailURL(with: [.medium, .original, .big, .large]) }
    }
 
    var contentFont: UIFont {
        
        guard case .karaoke(let config)? = appStateSlice.player.currentItem?.lyrics?.mode else {
            return UIFont.systemFont(ofSize: 17)
        }
        
        switch config.mode {
        case .scroll:
            return UIFont.systemFont(ofSize: 17.0)
        case .onePhrase:
            return UIFont.systemFont(ofSize: 32.0)
        }
        
    }
    
}

final class KaraokeViewModel: KaraokeCollectionViewFlowLayoutViewModel {

    // MARK: - Private properties -

    private(set) weak var router: KaraokeRouter?

    private var karaoke: Karaoke?
    private(set) var currentItemIndexPath: IndexPath?

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: KaraokeRouter) {
        self.router = router
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    


    func numberOfItems(in section: Int) -> Int {
        return self.karaoke?.intervals.count ?? 0
    }

    func item(at indexPath: IndexPath) -> DefaultKaraokeIntervalViewModel? {
        guard let karaoke = self.karaoke, karaoke.intervals.count > indexPath.item else { return nil }

        let karaokeInterval = karaoke.intervals[indexPath.item]
        let font = self.contentFont

        return DefaultKaraokeIntervalViewModel(font: font, karaokeInterval: karaokeInterval)
    }

    func itemSize(at indexPath: IndexPath, for width: CGFloat) -> CGSize {
        guard let karaoke = self.karaoke, karaoke.intervals.count > indexPath.item else { return CGSize.zero }

        let karaokeInterval = karaoke.intervals[indexPath.item]

        let font = self.contentFont
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = karaokeInterval.content.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)

        return CGSize(width: width, height: round(boundingBox.height))
    }

    func change(mode: PlayerState.Lyrics.Mode.KaraokeConfig.Mode) {
        guard case .karaoke(var config)? = appStateSlice.player.currentItem?.lyrics?.mode else {
            return
        }
        
        config.mode = mode
        
        let action = ChangeLyricsMode(to: .karaoke(config: config))
        
        Dispatcher.dispatch(action: action)
    }

    func changeAudioFileType() {
        
        guard case .karaoke(let config)? = appStateSlice.player.currentItem?.lyrics?.mode else {
            return
        }
        
        let action = ChangeLyricsMode(to: .karaoke(config: config.flipTrack))
        
        Dispatcher.dispatch(action: action)
        
    }

    func switchToLyrics() {
        Dispatcher.dispatch(action: ChangeLyricsMode(to: .plain))
    }
}
