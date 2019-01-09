//
//  RoundedButton.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
open class DesignableButton: UIButton {

    @IBInspectable
    public var isRounded: Bool = false {
        didSet {
            self.setNeedsLayout()
        }
    }

    override open var isEnabled: Bool {
        didSet { self.stateChanged() }
    }

    override open var isSelected: Bool {
        didSet { self.stateChanged() }
    }

    override open var isHighlighted: Bool {
        didSet { self.stateChanged() }
    }

    open override var clipsToBounds: Bool {
        get {
            guard isRounded == false else { return super.clipsToBounds }
            return true
        }

        set { super.clipsToBounds = newValue }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = isRounded ? min(self.bounds.midX, self.bounds.midY) : 0
    }

    private var borderWidthForState = [UInt : CGFloat]()
    private var borderColorForState = [UInt : UIColor]()

    private var backgroundColorForState = [UInt : UIColor]()

    open func setBorderWidth(_ borderWidth: CGFloat, for state: UIControl.State) {
        borderWidthForState[state.rawValue] = borderWidth
    }

    open func setBorderColor(_ borderColor: UIColor?, for state: UIControl.State) {
        borderColorForState[state.rawValue] = borderColor
    }

    open func setBackgroundColor(_ backgroundColor: UIColor, for state: UIControl.State) {
        backgroundColorForState[state.rawValue] = backgroundColor
    }

    open func borderWidth(for state: UIControl.State) -> CGFloat {
        return borderWidthForState[state.rawValue] ?? 0.0
    }

    open func borderColor(for state: UIControl.State) -> UIColor? {
        return borderColorForState[state.rawValue]
    }

    open func backgroundColor(for state: UIControl.State) -> UIColor? {
        return backgroundColorForState[state.rawValue]
    }

    private func stateChanged() {
        self.layer.borderWidth = self.borderWidth(for: self.state)
        self.layer.borderColor = self.borderColor(for: self.state)?.cgColor
        self.backgroundColor = self.backgroundColor(for: self.state)
    }
}
