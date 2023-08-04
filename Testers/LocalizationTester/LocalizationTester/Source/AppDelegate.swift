//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  AppDelegate.m
//  LocalizationTester
//
//  Created by Cameron Sabol on 12/11/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    @objc func keyboardDidShow() {
        (window!.rootViewController as? UINavigationController)?.topViewController?.view.endEditing(true)
    }
    
    var window: UIWindow?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        
        let rootVC = ViewController()
        let navigationController = UINavigationController(rootViewController: rootVC)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
}
