//
//  MVVM.swift
//   
//
//  Created by Vlad Soroka on 10/15/16.
//  Copyright © 2016  . All rights reserved.
//

import UIKit

////generic ViewController that requires all controllers to have ViewModels
protocol MVVM_View {
    
    associatedtype VM: MVVM_ViewModel
    
    ///until apple allows creating custom intializers for ViewControllers created from storyboards, we are using unwrapped optionals to shut up the compiler
    var viewModel: VM! { get }
}

protocol MVVM_ViewModel {
    
    associatedtype T: MVVM_Router
    
    var router: T { get }
    
}

protocol MVVM_Router {
    
    associatedtype T: NSObjectProtocol
    
    /*weak*/ var owner: T { get }
    
    var animatable: CanChangeAnimationStatus { get }
    var messagePresentable: CanPresentMessage { get }
}

extension MVVM_Router where T : UIViewController {
    
    var animatable: CanChangeAnimationStatus {
        return owner
    }
    
    var messagePresentable: CanPresentMessage {
        return owner
    }
    
}
