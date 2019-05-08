//
//  main.swift
//  RhythmicRebellion
//
//  Created by Andrey Ivanov on 5/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

private func delegateClassName() -> String? {
    
    if NSClassFromString("XCTestCase") == nil {
        return NSStringFromClass(AppDelegate.self)
    }
    else {
        Dispatcher.beginSerialExecution()
        return nil
    }
    
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName())
