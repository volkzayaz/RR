//
//  GenresContainerView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/12/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import CloudTagView

class GenresContainerView: UIControl {

    @IBOutlet weak var tagsView: TagsView!
    @IBOutlet weak var placeHolderLabel: UILabel!

    open override var intrinsicContentSize: CGSize {
        return tagsView.intrinsicContentSize
    }

    open override func awakeFromNib() {
        super.awakeFromNib()

        self.tagsView.delegate = self
    }

    var genres: [Genre]? {
        set { self.reload(with: newValue) }
        get { return internalGenres }
    }

    private var internalGenres: [Genre]? {
        didSet {

            self.placeHolderLabel.isHidden = self.internalGenres?.count ?? 0 > 0

            self.invalidateIntrinsicContentSize()
        }
    }

    override func invalidateIntrinsicContentSize() {
        self.tagsView.invalidateIntrinsicContentSize()
        super.invalidateIntrinsicContentSize()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }

    private func reload(with genres: [Genre]?) {
        self.internalGenres = genres

        if let genres = self.genres {
            self.tagsView.tags = genres.map({ (genre) -> TagView in
                let tagView = TagView(text: genre.name)
                tagView.backgroundColor = #colorLiteral(red: 0.04402898997, green: 0.1072343066, blue: 0.2928951979, alpha: 1)
                return tagView
            })
        } else {
            self.tagsView.tags.removeAll()
        }

        self.invalidateIntrinsicContentSize()
    }
}

extension GenresContainerView : TagViewDelegate {

    public func tagDismissed(_ tag: TagView) {
        guard let tagIndex = self.tagsView.tags.index(of: tag) else { return }
        self.internalGenres?.remove(at:  tagIndex)

        self.sendActions(for: .valueChanged)
    }

    public func tagTouched(_ tag: TagView) {
    }
}
