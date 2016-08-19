//
//  AppDelegate.swift
//  CarthageTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let rootVC = ViewController()
        let navigationController = UINavigationController(rootViewController: rootVC)
        let window = UIWindow()
        window.rootViewController = navigationController;
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
}

