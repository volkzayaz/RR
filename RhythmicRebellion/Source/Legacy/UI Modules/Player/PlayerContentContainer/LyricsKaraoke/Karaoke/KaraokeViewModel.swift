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

final class KaraokeViewModel: KaraokeViewModelProtocol {

    // MARK: - Private properties -

    private(set) weak var delegate: KaraokeViewModelDelegate?
    private(set) weak var router: KaraokeRouter?

    private var lyricsKaraokeService: LyricsKaraokeService

    private var karaoke: Karaoke?

    var viewMode: KaraokeViewMode { return self.lyricsKaraokeService.karaokeViewMode }

    private(set) var currentItemIndexPath: IndexPath?

    var isVocalAudioFile: Bool { return self.lyricsKaraokeService.karaokeAudioFileType.value == .original }
    var canChangeAudioFileType: Bool { return self.karaoke != nil
//                                            && self.player.currentItem.state.blocked == false
//                                            && self.player.currentItem.state.waitingAddons == false
//                                            && self.player.currentQueueItem?.isTrack == true
        
    }

    var isIdleTimerDisabled: Bool {
        get { return self.lyricsKaraokeService.isIdleTimerDisabled.value }
        set { self.lyricsKaraokeService.isIdleTimerDisabled.accept(newValue) }
    }

    let disposeBag = DisposeBag()

    // MARK: - Lifecycle -

    init(router: KaraokeRouter, lyricsKaraokeService: LyricsKaraokeService) {
        self.router = router
        self.lyricsKaraokeService = lyricsKaraokeService
    }

    private func contentFont() -> UIFont {
        switch self.viewMode {
        case .scroll:
            return UIFont.systemFont(ofSize: 17.0)
        case .onePhrase:
            return UIFont.systemFont(ofSize: 32.0)
        }
    }

    func findCurrentItemIndexPath() -> IndexPath? {

        return nil
        
//        guard let karaokeIntervals = self.karaoke?.intervals,
//            let currentItemTime = self.player.currentItemTime else { return nil }
//        guard let intervalIndex = karaokeIntervals.firstIndex(where: { (interval) -> Bool in
//            return TimeInterval(interval.start) <= currentItemTime + 0.3 && TimeInterval(interval.end) > currentItemTime }) else {
//
//            guard let previousIntervalIndex = karaokeIntervals.firstIndex(where: { (interval) -> Bool in
//                return TimeInterval(interval.start) > currentItemTime}) else { return nil }
//
//                return IndexPath(item: max(0, previousIntervalIndex - 1), section: 0)
//        }
//
//        return IndexPath(item: intervalIndex, section: 0)
    }

    func load(with delegate: KaraokeViewModelDelegate) {
        self.delegate = delegate


        self.lyricsKaraokeService.lyricsState.subscribe(onNext: { [unowned self] (lyricsState) in
            switch lyricsState {
            case .lyrics(let lyrics):
                self.karaoke = lyrics.karaoke
            default:
                self.karaoke = nil
            }

            self.currentItemIndexPath = self.findCurrentItemIndexPath()
            self.delegate?.reloadUI()
        })
        .disposed(by: disposeBag)


        self.lyricsKaraokeService.karaokeAudioFileType
            .subscribe(onNext: { [unowned self] (audioFileType) in
                self.delegate?.refreshUI()
            })
            .disposed(by: disposeBag)




        self.delegate?.reloadUI()
    }

    func thumbnailURL() -> URL? {
        return nil
//        guard let track = self.player.currentItem?.playlistItem.track else { return nil }
//        return track.thumbnailURL(with: [.medium, .original, .big, .large, .xlarge, .small, .xsmall, .thumb, .preload])
    }

    func numberOfItems(in section: Int) -> Int {
        return self.karaoke?.intervals.count ?? 0
    }

    func item(at indexPath: IndexPath) -> DefaultKaraokeIntervalViewModel? {
        guard let karaoke = self.karaoke, karaoke.intervals.count > indexPath.item else { return nil }

        let karaokeInterval = karaoke.intervals[indexPath.item]
        let font = self.contentFont()

        return DefaultKaraokeIntervalViewModel(font: font, karaokeInterval: karaokeInterval)
    }

    func itemSize(at indexPath: IndexPath, for width: CGFloat) -> CGSize {
        guard let karaoke = self.karaoke, karaoke.intervals.count > indexPath.item else { return CGSize.zero }

        let karaokeInterval = karaoke.intervals[indexPath.item]

        let font = self.contentFont()
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = karaokeInterval.content.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)

        return CGSize(width: width, height: round(boundingBox.height))
    }

    func change(viewMode: KaraokeViewMode) {

        guard self.lyricsKaraokeService.karaokeViewMode != viewMode else { return }

        self.lyricsKaraokeService.karaokeViewMode = viewMode
        self.delegate?.refreshUI()
    }

    func changeAudioFileType() {

        switch self.lyricsKaraokeService.karaokeAudioFileType.value {
        case .original: self.lyricsKaraokeService.karaokeAudioFileType.accept(.backing)
        case .clean: self.lyricsKaraokeService.karaokeAudioFileType.accept(.original)
        default: self.lyricsKaraokeService.karaokeAudioFileType.accept(.original)
        }
    }

    func switchToLyrics() {
        self.lyricsKaraokeService.mode.accept(.lyrics)
    }
}

extension KaraokeViewModel {

    func player(didChangeBlockedState isBlocked: Bool) {
        self.delegate?.refreshUI()
    }

    func player(didChangePlayerQueueItem playerQueueItem: Void/*PlayerQueueItem*/) {

        self.currentItemIndexPath = self.findCurrentItemIndexPath()
        self.delegate?.refreshUI()
    }

    func player(didChangePlayerItemCurrentTime time: TimeInterval) {
        guard let currentItemIndexPath = self.findCurrentItemIndexPath(), self.currentItemIndexPath != currentItemIndexPath else { return }

        self.currentItemIndexPath = currentItemIndexPath

        self.delegate?.refreshUI()
    }
}