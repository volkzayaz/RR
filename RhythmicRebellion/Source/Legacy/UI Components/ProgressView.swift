//
//  ProgressView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class KaraokeIntervalView: UIView {

    let startValue: CGFloat
    let endValue: CGFloat

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(with viewModel: KaraokeIntervalProgressViewModel) {
        self.startValue = CGFloat(viewModel.startValue)
        self.endValue = CGFloat(viewModel.endValue)

        super.init(frame: CGRect.zero)

        self.backgroundColor = viewModel.color
    }
}

@IBDesignable
class ProgressView: UISlider {

    @IBInspectable
    var restrictedTrackTintColor: UIColor = UIColor.clear {
        didSet { self.setNeedsDisplay() }
    }

    var restrictedValue: Float? {
        didSet { self.setNeedsDisplay() }
    }

    var karaokeIntervalsViewModelId: Int?
    var karaokeIntervalViews: [KaraokeIntervalView] = []

    func frame(for karaokeIntervalView: KaraokeIntervalView, in bounds: CGRect, thumbRect: CGRect) -> CGRect {

        let origin = CGPoint(x: ((bounds.width - thumbRect.width) * karaokeIntervalView.startValue + thumbRect.width).rounded(),
                             y: bounds.minY + 0.5)
        
        let size = CGSize(width: ((bounds.width - thumbRect.width) * karaokeIntervalView.endValue + thumbRect.width - origin.x).rounded(),
                          height: bounds.height - 1)

        return CGRect(origin: origin, size: size)
    }

    func update(with karaokeIntervalsViewModel: KaraokeIntervalsProgressViewModel?) {
        guard karaokeIntervalsViewModel?.id != self.karaokeIntervalsViewModelId else { return }

        karaokeIntervalViews.forEach( { $0.removeFromSuperview() })
        karaokeIntervalViews.removeAll()

        let trackRect = self.trackRect(forBounds: self.bounds)
        let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: trackRect, value: self.value)

        karaokeIntervalsViewModel?.intervals.forEach( {

            let karaokeIntervalView = KaraokeIntervalView(with: $0)
            karaokeIntervalView.frame = self.frame(for: karaokeIntervalView, in: trackRect, thumbRect: thumbRect)

            self.insertSubview(karaokeIntervalView, at: 0)

            self.karaokeIntervalViews.append(karaokeIntervalView)
        })

        self.karaokeIntervalsViewModelId = karaokeIntervalsViewModel?.id
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let trackRect = self.trackRect(forBounds: self.bounds)
        let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: trackRect, value: self.value)

        karaokeIntervalViews.forEach {
            $0.frame = self.frame(for: $0, in: trackRect, thumbRect: thumbRect)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let restrictedValue = self.restrictedValue, restrictedValue > 0.0 {
            var restrictedTrackRect = self.trackRect(forBounds: self.bounds)
            let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: restrictedTrackRect, value: self.value)
            restrictedTrackRect.size.width = ((self.bounds.width - thumbRect.width) * CGFloat(restrictedValue) + thumbRect.width).rounded() - 2 * restrictedTrackRect.origin.x
            restrictedTrackRect.origin.x += 1

            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()

            context?.setFillColor(self.restrictedTrackTintColor.cgColor)
            context?.fill(restrictedTrackRect)

            context?.restoreGState()
        }
    }
}
