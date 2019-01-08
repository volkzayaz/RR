//
//  KaraokeControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

final class KaraokeControllerViewModel: KaraokeViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: KaraokeViewModelDelegate?
    private(set) weak var router: KaraokeRouter?

    private(set) var player: Player

    private var karaoke: Karaoke? { return self.player.currentItem?.lyrics?.karaoke }

    private(set) var viewMode: KaraokeViewMode
    private(set) var currentItemIndexPath: IndexPath?

    var isVocalAudioFile: Bool { return self.player.karaokeAudioFileType == .vocal }
    var canChangeAudioFileType: Bool { return self.player.canChangeKaraokeAudioFileType }

    // MARK: - Lifecycle -

    deinit {
        self.player.removeWatcher(self)
    }

    init(router: KaraokeRouter, player: Player) {
        self.router = router
        self.player = player

        self.viewMode = .onePhrase
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

        guard let karaokeIntervals = self.karaoke?.intervals, let currentItemTime = self.player.currentItemTime else { return nil }
        guard let intervalIndex = karaokeIntervals.firstIndex(where: { (interval) -> Bool in
            return TimeInterval(interval.start) <= currentItemTime + 0.3 && TimeInterval(interval.end) > currentItemTime }) else {

            guard let previousIntervalIndex = karaokeIntervals.firstIndex(where: { (interval) -> Bool in
                return TimeInterval(interval.start) > currentItemTime}) else { return nil }

                return IndexPath(item: max(0, previousIntervalIndex - 1), section: 0)
        }

        return IndexPath(item: intervalIndex, section: 0)
    }

    func load(with delegate: KaraokeViewModelDelegate) {
        self.delegate = delegate

        self.currentItemIndexPath = self.findCurrentItemIndexPath()

        self.delegate?.reloadUI()

        self.player.addWatcher(self)
    }

    func thumbnailURL() -> URL? {
        guard let track = self.player.currentItem?.playlistItem.track else { return nil }
        return track.thumbnailURL(with: [.medium, .original, .big, .large, .xlarge, .small, .xsmall, .thumb, .preload])
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

    func itemViewHeight(at indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        guard let karaoke = self.karaoke, karaoke.intervals.count > indexPath.item else { return 0.0 }

        let karaokeInterval = karaoke.intervals[indexPath.item]

        let font = self.contentFont()
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = karaokeInterval.content.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return round(boundingBox.height)
    }

    func change(viewMode: KaraokeViewMode) {

        guard self.viewMode != viewMode else { return }

        self.viewMode = viewMode
        self.delegate?.refreshUI()
    }

    func changeAudioFileType() {

        switch self.player.karaokeAudioFileType {
        case .vocal: self.player.change(karaokeAudioFileType: .clean)
        case .clean: self.player.change(karaokeAudioFileType: .vocal)
        }

        self.delegate?.refreshUI()
    }

    func switchToLyrics() {
        self.player.switchTo(karaokeMode: .lyrics)
    }
}

extension KaraokeControllerViewModel: PlayerWatcher {

    func player(player: Player, didChangePlayerItem playerItem: PlayerItem?) {

        self.currentItemIndexPath = nil
        self.delegate?.reloadUI()
    }

    func player(player: Player, didChangePlayerQueueItem playerQueueItem: PlayerQueueItem) {
        self.currentItemIndexPath = nil
        self.delegate?.refreshUI()
    }

    func player(player: Player, didChangePlayerItemCurrentTime time: TimeInterval) {
        guard let currentItemIndexPath = self.findCurrentItemIndexPath(), self.currentItemIndexPath != currentItemIndexPath else { return }

        self.currentItemIndexPath = currentItemIndexPath

        self.delegate?.refreshUI()
    }


    func player(player: Player, didLoadPlayerItemLyrics lyrics: Lyrics) {

        self.currentItemIndexPath = self.findCurrentItemIndexPath()
        self.delegate?.refreshUI()
    }
}
