//
//  main.swift
//  RhythmicRebellion
//
//  Created by Andrey Ivanov on 5/7/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

private func delegateClassName() -> String? {
    return NSClassFromString("XCTestCase") == nil ? NSStringFromClass(AppDelegate.self) : nil
}

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, delegateClassName())
