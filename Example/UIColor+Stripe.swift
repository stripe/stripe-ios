//
//  Color.swift
//  Standard Integration
//
//  Created by Yuki Tokuhiro on 5/31/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

extension UIColor {
    // Swift unfortunately doesn't yet have a clean way of checking for iOS 13 at compile-time, so we attempt to import CryptoKit, a framework that only exists on iOS 13.
    // We can delete all of these awful #if canImport() blocks once the iOS 13 SDK is required for App Store submissions, probably ~March 2020.
    static let stripeBrightGreen : UIColor = {
        var color = UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            color = UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0) :
                    UIColor(red: 39/255, green: 213/255, blue: 149/255, alpha: 1.0)
            })
        }
        #endif
        return color
    }()
    static let stripeDarkBlue : UIColor = {
        var color = UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            color = UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0) :
                    UIColor(red: 121/255, green: 142/255, blue: 188/255, alpha: 1.0)
            })
        }
        #endif
        return color
    }()
}
