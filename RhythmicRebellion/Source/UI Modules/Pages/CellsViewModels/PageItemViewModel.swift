//
//  PageItemViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

struct PageItemViewModel: PageItemCollectionViewCellViewModel {

    var id: Int { return page.id }

    let page: Page
    let image: UIImage?
}
