//
//  RhythmicRebellion.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit

protocol FlowRouter: class {

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool

    func prepare(for segue: UIStoryboardSegue, sender: Any?)
}

protocol SegueDestinations {
    var identifier: String { get }

    static func from(identifier: String) -> Self?
}

protocol SegueCompatible  {

    var sourceController: UIViewController? { get }
    associatedtype Destinations: SegueDestinations

}

extension SegueCompatible {

    func merge(segue: UIStoryboardSegue, with sender: Any?) -> Destinations? {

        if let destination = sender as? Destinations, segue.identifier == destination.identifier {
            return destination
        }

        let dest = Destinations.from(identifier: segue.identifier!)
        assert(dest != nil, "Unsupported segue: \(segue)")
        return dest
    }

    func performSegue(to destination: Destinations) {
        sourceController?.performSegue(withIdentifier: destination.identifier, sender: destination)
    }
}

struct RouterDependencies {
    let webSocketService: WebSocketService
}
