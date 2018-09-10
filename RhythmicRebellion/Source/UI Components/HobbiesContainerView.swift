//
//  HobbiesCloudTagView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/8/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import CloudTagView


class HobbyTagView: TagView {

    let hobby: Hobby

    init(with hobby: Hobby) {

        self.hobby = hobby
        super.init(text: hobby.name)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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

            self.cloudTagView.invalidateIntrinsicContentSize()
            self.invalidateIntrinsicContentSize()

            self.sendActions(for: .valueChanged)
        }
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
        guard let tagIndex = self.cloudTagView.tags.firstIndex(of: tag) else { return }
        self.internalHobbies?.remove(at:  tagIndex)
    }

    public func tagTouched(_ tag: TagView) {
    }
}



