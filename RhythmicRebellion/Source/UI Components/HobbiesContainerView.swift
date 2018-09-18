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

    @IBOutlet weak var tagsView: TagsView!
    @IBOutlet weak var placeHolderLabel: UILabel!

    open override var intrinsicContentSize: CGSize {
        return tagsView.intrinsicContentSize
    }

    open override func awakeFromNib() {
        super.awakeFromNib()

        self.tagsView.delegate = self
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
//        self.tagsView.invalidateIntrinsicContentSize()
        super.invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }

    private func reload(with hobbies: [Hobby]?) {
        self.internalHobbies = hobbies

        if let hobbies = self.hobbies {
            self.tagsView.tags = hobbies.map({ (hobby) -> TagView in
                let tagView = TagView(text: hobby.name)
                tagView.translatesAutoresizingMaskIntoConstraints = false
                tagView.backgroundColor = #colorLiteral(red: 0.04402898997, green: 0.1072343066, blue: 0.2928951979, alpha: 1)
                return tagView
            })
        } else {
            self.tagsView.tags.removeAll()
        }

        self.invalidateIntrinsicContentSize()
    }
}

extension HobbiesContainerView : TagViewDelegate {

    public func tagDismissed(_ tag: TagView) {
        guard let tagIndex = self.tagsView.tags.index(of: tag) else { return }
        self.internalHobbies?.remove(at:  tagIndex)

        self.sendActions(for: .valueChanged)
    }

    public func tagTouched(_ tag: TagView) {
    }
}
