//
//  Cell+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol CellIdentifiable {

    static var identifier: String { get }
}

extension CellIdentifiable where Self: UICollectionViewCell {

    static func reusableCell(in collectionView: UICollectionView, at indexPath: IndexPath) -> Self {
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! Self
    }
}

extension CellIdentifiable where Self: UICollectionReusableView {

    static func makeView(in collectionView: UICollectionView, at indexPath: IndexPath, ofKind kind: String = UICollectionView.elementKindSectionHeader) -> Self {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: identifier,
                                                               for: indexPath) as! Self
    }
}

extension CellIdentifiable where Self: UITableViewCell {

    static func reusableCell(in tableView: UITableView, at indexPath: IndexPath) -> Self {
        return tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! Self
    }
}
