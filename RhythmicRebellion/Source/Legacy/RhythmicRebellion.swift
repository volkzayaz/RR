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

protocol SegueDestinationList {

    var rawValue: String { get }

    init?(rawValue: String)

    init?(segue: UIStoryboardSegue)
}

protocol SegueDestinations {

    var identifier: SegueDestinationList { get }

    init?(destinationList: SegueDestinationList)
}

extension SegueDestinations {

    init?(destinationList: SegueDestinationList) {
        return nil
    }

}

extension SegueDestinationList {

    init?(segue: UIStoryboardSegue) {
        guard
            let identifier = segue.identifier,
            let newSegue = Self.init(rawValue: identifier) else
        {
            assert(false, "Unexpected segue identifier - \(String(describing: segue.identifier))")
            return nil
        }

        self = newSegue
    }
}

extension UIViewController {

    func performSegue(_ segue: SegueDestinationList, sender: Any?) {
        self.performSegue(withIdentifier: segue.rawValue, sender: sender)
    }
}

protocol SegueDestinationsCompatible {

    var sourceController: UIViewController? { get }

    associatedtype DestinationsList: SegueDestinationList

    associatedtype Destinations: SegueDestinations

}

extension SegueDestinationsCompatible {

    fileprivate func merge(segue: UIStoryboardSegue, with sender: Any?) -> Destinations? {
        if let destination = sender as? Destinations, segue.identifier == destination.identifier.rawValue {
            return destination
        }

        if let id = segue.identifier, let destinationList = DestinationsList(rawValue: id) {

            if let destination = Destinations(destinationList: destinationList) {
                return destination
            }

            if !id.hasPrefix("backTo") { // Always ignore unwind segues
                print("Segue `\(id)` has no destination -> action ignored")

            }
            return nil;
        }

        print("Unknown segue identifier: \(segue.identifier ?? "nil")")
        return nil
    }

    func perform(segue: Destinations) {
        sourceController?.performSegue(withIdentifier: segue.identifier.rawValue, sender: segue)
    }
}

extension UIStoryboardSegue {

    func actualDestination<T: UIViewController>() -> T {
        let navigationController = self.destination as? UINavigationController
        let topController = navigationController?.topViewController ?? self.destination
        guard let top = topController as? T else {
            fatalError("Unable to cast \(String(describing: navigationController?.topViewController)) to \(T.self)")
        }
        return top
    }
}

protocol FlowRouterSegueCompatible: FlowRouter, SegueDestinationsCompatible {

    func canPerform(segue: DestinationsList) -> Bool

    func prepare(for destination: Destinations, segue: UIStoryboardSegue)

}

extension FlowRouterSegueCompatible {

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let segueList = DestinationsList(rawValue: identifier) else {
            print("Unknown segue identifier: \(identifier)")
            return false
        }

        return canPerform(segue: segueList)
    }

    func canPerform(segue: DestinationsList) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = merge(segue: segue, with: sender) else {
            return
        }
        prepare(for: destination, segue: segue)
    }
}

struct PresentationSource {

    let sourceView: UIView?

    let sourceRect: CGRect

    let barButtonItem: UIBarButtonItem?
}

struct RouterDependencies {

    var pagesLocalStorageService: PagesLocalStorageService { return daPlayer.pagesLocalStorageService }
    
    var webSocketService: WebSocketService {
        return daPlayer.webSocket
    }
    
    let daPlayer: RRPlayer!
    
}

typealias DataLayer = RouterDependencies

extension RouterDependencies {
    static var get: RouterDependencies {
        return (UIApplication.shared.delegate! as! AppDelegate).appRouter!.dependencies
    }
}
