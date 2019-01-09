//
//  ContainerTransitionSegue.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/19/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

protocol ContainerViewController: class {

    var containerView: UIView! { get }

    var currentViewController: UIViewController? { get set }
}

class ContainerTransitionSegue: UIStoryboardSegue {

    var containerViewController: (UIViewController & ContainerViewController)? { return self.source as? UIViewController & ContainerViewController }

    override func perform() {

        guard let containerViewController = self.containerViewController else { print("Bad source for segue"); return }

        containerViewController.addChild(self.destination)

        guard let currentViewController = containerViewController.currentViewController else {

            containerViewController.containerView.addSubview(self.destination.view)

            self.destination.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([self.destination.view.topAnchor.constraint(equalTo: containerViewController.containerView.topAnchor),
                                         self.destination.view.leftAnchor.constraint(equalTo: containerViewController.containerView.leftAnchor),
                                         self.destination.view.bottomAnchor.constraint(equalTo: containerViewController.containerView.bottomAnchor),
                                         self.destination.view.rightAnchor.constraint(equalTo: containerViewController.containerView.rightAnchor)])
            self.destination.didMove(toParent: containerViewController)
            containerViewController.currentViewController = self.destination
            return
        }

        let destinationViewController = self.destination

        destinationViewController.view.frame = containerViewController.containerView.bounds

        currentViewController.willMove(toParent: nil)

        containerViewController.transition(from: currentViewController,
                                           to: destinationViewController,
                                           duration: 0.0,
                                           options: [.layoutSubviews],
                                           animations: {
                                             destinationViewController.view.frame = containerViewController.containerView.bounds
                                            }) { [currentViewController, destinationViewController, containerViewController] (success) in
                                                guard success == true else { destinationViewController.removeFromParent(); return }

                                                self.destination.view.translatesAutoresizingMaskIntoConstraints = false
                                                NSLayoutConstraint.activate([self.destination.view.topAnchor.constraint(equalTo: containerViewController.containerView.topAnchor),
                                                                             self.destination.view.leftAnchor.constraint(equalTo: containerViewController.containerView.leftAnchor),
                                                                             self.destination.view.bottomAnchor.constraint(equalTo: containerViewController.containerView.bottomAnchor),
                                                                             self.destination.view.rightAnchor.constraint(equalTo: containerViewController.containerView.rightAnchor)])

                                                currentViewController.removeFromParent()

                                                destinationViewController.didMove(toParent: containerViewController)

                                                containerViewController.currentViewController = destinationViewController
                                            }
    }
}
