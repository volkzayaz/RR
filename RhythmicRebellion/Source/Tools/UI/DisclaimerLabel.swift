//
//  DisclaimerLabel.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/17/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class DisclaimerLabel: UILabel {
    
    var layoutManager: NSLayoutManager!
    var textContainer: NSTextContainer!
    var textStorage: NSTextStorage!
    
    var links: [NSRange: URL]!
    
//    I have read and agree to the Standard Terms of User, Privacy Policy and Creative Supplemental Terms & Conditions for Content Creators
    
    func prepare(content: String, links: [NSRange: URL]) {
        
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapOnLabel:"))
        
        self.links = links
        
        let attributedString = NSMutableAttributedString(string: content, attributes: [
            .font: UIFont.systemFont(ofSize: 11.0, weight: .regular),
            .foregroundColor: UIColor(fromHex: 0xB1B9FF),
            .kern: -0.24
            ])
        
        links.forEach { (key: NSRange, value: URL) in
            attributedString.addAttributes([
                .foregroundColor: UIColor.blue,
                .underlineStyle: 1,
                .kern: -0.22
                ], range: key)
        }
        
        attributedText = attributedString
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        layoutManager = NSLayoutManager()
        textContainer = NSTextContainer(size: .zero)
        textStorage = NSTextStorage(attributedString: attributedString)
        
        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0;
        textContainer.lineBreakMode = lineBreakMode;
        textContainer.maximumNumberOfLines = numberOfLines;
        
    }
    
    @objc func tapOnLabel(_ tapGesture: UITapGestureRecognizer) {
        
        textContainer.size = bounds.size
        
        let locationOfTouchInLabel = tapGesture.location(in: tapGesture.view)
        let labelSize = tapGesture.view!.bounds.size
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y);
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y);
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                            in: textContainer,
                                                            fractionOfDistanceBetweenInsertionPoints: nil)
        
        for (key, value) in links {
            
            if (NSLocationInRange(indexOfCharacter, key)) {
                // Open an URL, or handle the tap on the link in any other way
                UIApplication.shared.open(value, options: [:])
            }
            
        }
        
    }
    
}
