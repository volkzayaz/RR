//
//  SplashViewController.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 5/13/19.
//Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import SwiftGifOrigin

class SplashViewController: UIViewController, MVVM_View {
    
    lazy var viewModel: SplashViewModel! = SplashViewModel(router: .init(owner: self))
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.loadGif(name: "splash")

        viewModel.finishedLoading
            .drive(onNext: { [unowned self] (_) in
                
                let x = R.storyboard.main.rootViewController()!
                
                x.viewModel = .init(router: .init(owner: x))
                x.transitioningDelegate = self
                
                //UIApplication.shared.keyWindow!.rootViewController = appViewController
                self.present(x, animated: true, completion: nil)
                
            })
            .disposed(by: rx.disposeBag)
        
        /**
         *  Set up any bindings here
         *  viewModel.labelText
         *     .drive(label.rx.text)
         *     .addDisposableTo(rx_disposeBag)
         */
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension SplashViewController: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.8
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        
        containerView.addSubview(toView)
        toView.alpha = 0.0
        UIView.animate(withDuration: 0.8,
                       animations: {
                        toView.alpha = 1.0
        },
                       completion: { _ in
                        transitionContext.completeTransition(true)
        }
        )
        
    }
    
    
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    
    
    /**
     *  Describe any IBActions here
     *
     
     @IBAction func performAction(_ sender: Any) {
     
     }
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
     }
 
    */
    
}
