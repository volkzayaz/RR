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

    deinit {
        self.dismissTimer?.invalidate()
        self.touchView?.removeFromSuperview()
    }

    func showTouched(forView view: UIView, withinSuperview superview: UIView) {
        guard self.touchView == nil else { return }

        let touchView = TipTouchView(frame: superview.bounds, tipView: self)
        superview.addSubview(touchView)

        self.show(forView: view, withinSuperview: superview)
        self.touchView = touchView

        self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] (timer) in
            self?.dismissTouched()
        }

    }

    func dismissTouched() {

        self.dismissTimer?.invalidate()
        self.touchView?.removeFromSuperview()

        super.dismiss()
    }
}
