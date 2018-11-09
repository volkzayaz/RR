//
//  TipView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/17/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import EasyTipView

class TipTouchView: UIView {

    weak var tipView: TipView?

    init(frame: CGRect, tipView: TipView) {
        super.init(frame: frame)
        self.tipView = tipView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let _ = super.hitTest(point, with: event) else { return nil }

        self.tipView?.dismissTouched()

        return nil
    }

}

class TipView: EasyTipView {

    private weak var dismissTimer: Timer?
    private weak var touchView: TipTouchView?

    private weak var targetView: UIView?

    deinit {
        self.dismissTimer?.invalidate()
        self.touchView?.removeFromSuperview()
    }

    func touchViewFrame(in view: UIView) -> CGRect {

        switch view {
        case let scrollView as UIScrollView:
            return scrollView.bounds

        default: return view.bounds
        }


    }

    func showTouched(forView view: UIView, in superview: UIView) {
        guard self.touchView == nil else { return }

        let refViewFrame = view.convert(view.bounds, to: superview)
        print("refViewFrame: \(refViewFrame)")

        let touchView = TipTouchView(frame: self.touchViewFrame(in: superview), tipView: self)
        superview.addSubview(touchView)

        self.show(forView: view, withinSuperview: superview)
        self.touchView = touchView

        self.targetView = view

        self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] (timer) in
            self?.dismissTouched()
        }

    }

    func dismissTouched() {

        self.dismissTimer?.invalidate()
        self.touchView?.removeFromSuperview()

        super.dismiss()
    }

    fileprivate func frame(arrowPosition position: ArrowPosition, refViewFrame: CGRect, superviewFrame: CGRect) -> CGRect {
        var xOrigin: CGFloat = 0
        var yOrigin: CGFloat = 0

        switch position {
        case .top, .any:
            xOrigin = refViewFrame.midX - self.bounds.width / 2
            yOrigin = refViewFrame.midY + refViewFrame.height
        case .bottom:
            xOrigin = refViewFrame.midX - self.bounds.width / 2
            yOrigin = refViewFrame.origin.y - self.bounds.height
        case .right:
            xOrigin = refViewFrame.origin.x - self.bounds.width
            yOrigin = refViewFrame.midY - self.bounds.height / 2
        case .left:
            xOrigin = refViewFrame.origin.x + refViewFrame.width
            yOrigin = refViewFrame.origin.y - self.bounds.height / 2
        }

        var frame = CGRect(x: xOrigin, y: yOrigin, width: self.bounds.width, height: self.bounds.height)

        if frame.origin.x < 0 {
            frame.origin.x =  0
        } else if frame.maxX > superviewFrame.width {
            frame.origin.x = superviewFrame.width - frame.width
        }

        //adjust vertically
        if frame.origin.y < 0 {
            frame.origin.y = 0
        } else if frame.maxY > superviewFrame.maxY {
            frame.origin.y = superviewFrame.height - frame.height
        }
        return frame
    }


    func updateFrame() {
        guard let targetView = self.targetView else { return }

        let refViewFrame = targetView.convert(targetView.bounds, to: superview);

        let superviewFrame: CGRect
        if let scrollview = superview as? UIScrollView {
            superviewFrame = CGRect(origin: scrollview.frame.origin, size: scrollview.contentSize)
        } else {
            superviewFrame = superview?.frame ?? CGRect.zero
        }

        self.frame = self.frame(arrowPosition: preferences.drawing.arrowPosition, refViewFrame: refViewFrame, superviewFrame: superviewFrame)
    }

}
