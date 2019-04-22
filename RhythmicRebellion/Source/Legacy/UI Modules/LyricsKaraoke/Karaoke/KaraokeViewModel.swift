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
import RxDataSources

extension KaraokeViewModel {
    
    struct Data {

        let layout: KaraokeLayout
        let viewModels: [KaraokeIntervalCellViewModel]
        let activeIndex: Int?
        
        let change: ChangeType?
        
        init(layout: KaraokeLayout, viewModels: [KaraokeIntervalCellViewModel], activeIndex: Int?, compareTo: Data?) {
            self.layout = layout
            self.viewModels = viewModels
            self.activeIndex = activeIndex
            
            guard let x = compareTo else {
                change = .layout
                return
            }
            
            if type(of: layout) != type(of: x.layout) {
                change = .layout
            }
            else if viewModels != compareTo?.viewModels {
                change = .data
            }
            else if activeIndex != compareTo?.activeIndex {
                change = .index
            }
            else {
                change = nil
            }
        }
        
        enum ChangeType {
            case layout
            case data
            case index
        }
        
    }
    
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
        }
    }
    
    var thumbnailURL: Driver<URL?> {
        return appState.map { $0.currentTrack?.track }
            .distinctUntilChanged()
            .map { $0?.thumbnailURL(with: [.medium, .original, .big, .large]) }
    }
    
}

struct KaraokeViewModel {

    private let karaoke = BehaviorRelay<Karaoke?>(value: nil)

    let data = BehaviorRelay<Data?>(value: nil)
    
    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: KaraokeRouter) {
        self.router = router
        
        appState.map { $0.player.currentItem?.lyrics?.data.karaoke }
            .distinctUntilChanged()
            .drive(karaoke)
            .disposed(by: disposeBag)
        
        let progressChanges = appState.map { $0.player.currentItem?.state.progress }
            .notNil()
            .distinctUntilChanged()
        
        let dataChanges = Driver.combineLatest(mode, karaoke.asDriver()) { (mode, maybeKaraoke) -> (KaraokeLayout, [KaraokeIntervalCellViewModel]) in
            
            let data = (maybeKaraoke?.intervals ?? []).map { i in
                return KaraokeIntervalCellViewModel(font: mode.font,
                                                    karaokeInterval: i)
            }
            
            return (mode.layout, data)
        }
        
        Driver.combineLatest(progressChanges, dataChanges) { (progress, data) -> (KaraokeLayout, [KaraokeIntervalCellViewModel], Int?) in
            
                let calculateIndex = { () -> Int? in
                    for (index, viewModel) in data.1.enumerated() {
                    
                        if viewModel.karaokeInterval.range ~= progress {
                            return index
                        }
                    
                        if viewModel.karaokeInterval.range.lowerBound > progress {
                            return max(0, index - 1)
                        }
                    
                    }
                
                    return nil
                }
            
                return (data.0, data.1, calculateIndex())
            }
            .scan(nil) { (maybePreviousData, input) -> Data? in
                return Data(layout: input.0, viewModels: input.1, activeIndex: input.2, compareTo: maybePreviousData)
            }
            .drive(data)
            .disposed(by: disposeBag)
        
    }

    func itemSize(at indexPath: IndexPath, for width: CGFloat) -> CGSize {
        guard let karaoke = self.karaoke.value,
              karaoke.intervals.count > indexPath.item,
              case .karaoke(let config)? = appStateSlice.player.currentItem?.lyrics?.mode else {
                return CGSize.zero
        }
        
        let karaokeInterval = karaoke.intervals[indexPath.item]
        
        let font =  config.mode.font
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = karaokeInterval.content.boundingRect(with: constraintRect,
                                                               options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                               attributes: [NSAttributedString.Key.font: font], context: nil)

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
    
    private(set) weak var router: KaraokeRouter?

    
}


extension PlayerState.Lyrics.Mode.KaraokeConfig.Mode {
    
    var font: UIFont {
        
        switch self {
        case .scroll:     return .systemFont(ofSize: 17.0)
        case .onePhrase:  return .systemFont(ofSize: 32.0)
        
        }
        
    }
    
    var layout: KaraokeLayout {
        switch self {
        case .scroll:     return KaraokeScrollLayout()
        case .onePhrase:  return KaraokeOnePhraseLayout()
            
        }
    }
    
}
