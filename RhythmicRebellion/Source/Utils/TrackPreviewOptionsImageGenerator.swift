//
//  TrackPreviewOptionsFormatter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class TrackPreviewOptionsImageGenerator {

    let font: UIFont
    var cachedImages: [String : UIImage]

    init(font: UIFont) {
        self.font = font
        cachedImages = [String : UIImage]()
    }


    func image(for track: Track, trackTotalPlayMSeconds: UInt64?, user: User?) -> UIImage? {

        guard track.isFreeForPlaylist == false else { return UIImage(named: "InfinityMark") }
        guard let _ = user as? FanUser else { return self.guestImage(for: track) }


        switch track.previewType {
        case .full:
            guard let previewLimitTimes = track.previewLimitTimes else { return UIImage(named: "InfinityMark") }
            guard let trackDuration = track.audioFile?.duration, previewLimitTimes > 0 else { return self.imageFor(for: "0") }
            guard let trackTotalPlayMSeconds = trackTotalPlayMSeconds else { return self.imageFor(for: String(previewLimitTimes)) }

            let trackMaxPlayMSeconds = UInt64(trackDuration * 1000 * previewLimitTimes)
            guard trackMaxPlayMSeconds > trackTotalPlayMSeconds else { return self.imageFor(for: "0") }

            let previewTimes = Int((trackMaxPlayMSeconds - trackTotalPlayMSeconds) / UInt64(trackDuration * 1000))
            return self.imageFor(for: String(previewTimes))

        case .limit45: return self.imageFor(for: "45s")
        case .limit90: return self.imageFor(for: "90s")

        case .noPreview: return UIImage(named: "DashMark")
        default: return nil
        }
    }

    func guestImage(for track: Track) -> UIImage? {

        switch track.previewType {
        case .full:
            guard let _ = track.previewLimitTimes else { return UIImage(named: "InfinityMark") }
            return self.imageFor(for: "!")
        default: return self.imageFor(for: "!")
        }
    }

    func imageFor(for text: String) -> UIImage? {

        var cachedImage = self.cachedImages[text]

        if cachedImage == nil {
            let attributes = [NSAttributedStringKey.font: self.font] as [NSAttributedStringKey : Any]

            let stringSize = text.size(withAttributes: attributes)

            UIGraphicsBeginImageContextWithOptions(stringSize, false, 0)
            text.draw(in: CGRect(origin: CGPoint.zero, size: stringSize), withAttributes: attributes)
            cachedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            self.cachedImages[text] = cachedImage

        }

        return cachedImage
    }
}
