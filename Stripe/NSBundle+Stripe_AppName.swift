//
//  NSBundle+Stripe_AppName.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension Bundle {
    class func stp_applicationName() -> String? {
        return self.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    class func stp_applicationVersion() -> String? {
        return self.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    class var displayName: String? {
        return self.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? self.main
            .object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}
