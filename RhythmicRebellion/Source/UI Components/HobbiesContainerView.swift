//
//  HobbiesCloudTagView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/8/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import CloudTagView

class HobbiesContainerView: UIControl {

    @IBOutlet weak var cloudTagView: CloudTagView!
    @IBOutlet weak var placeHolderLabel: UILabel!

    open override var intrinsicContentSize: CGSize {
        return cloudTagView.intrinsicContentSize
    }

    open override func awakeFromNib() {
        super.awakeFromNib()

        self.cloudTagView.delegate = self
    }

    var hobbies: [Hobby]? {
        set { self.reload(with: newValue) }
        get { return internalHobbies }
    }

    private var internalHobbies: [Hobby]? {
        didSet {

            self.placeHolderLabel.isHidden = self.internalHobbies?.count ?? 0 > 0

            self.invalidateIntrinsicContentSize()
        }
    }

    override func invalidateIntrinsicContentSize() {
        self.cloudTagView.invalidateIntrinsicContentSize()
        super.invalidateIntrinsicContentSize()
    }

    private func reload(with hobbies: [Hobby]?) {
        self.internalHobbies = hobbies

        if let hobbies = self.hobbies {
            self.cloudTagView.tags = hobbies.map({ (hobby) -> TagView in
                let tagView = TagView(text: hobby.name)
                tagView.backgroundColor = #colorLiteral(red: 0.04402898997, green: 0.1072343066, blue: 0.2928951979, alpha: 1)
                return tagView
            })
        } else {
            self.cloudTagView.tags.removeAll()
        }
    }
}

extension HobbiesContainerView : TagViewDelegate {

    public func tagDismissed(_ tag: TagView) {
        guard let tagIndex = self.cloudTagView.tags.index(of: tag) else { return }
        self.internalHobbies?.remove(at:  tagIndex)

        self.sendActions(for: .valueChanged)
    }

    public func tagTouched(_ tag: TagView) {
    }
}
