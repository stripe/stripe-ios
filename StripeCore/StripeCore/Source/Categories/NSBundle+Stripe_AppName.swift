//
//  NSBundle+Stripe_AppName.swift
//  StripeCore
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

extension Bundle {
    @_spi(STP) public class func stp_applicationName() -> String? {
        return self.main.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    @_spi(STP) public class func stp_applicationVersion() -> String? {
        return self.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    @_spi(STP) public class func stp_applicationBundleId() -> String? {
        return self.main.bundleIdentifier
    }

    @_spi(STP) public class func buildVersion() -> String? {
        return self.main.infoDictionary?["CFBundleVersion"] as? String
    }

    @_spi(STP) public class var displayName: String? {
        return self.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? self.main
            .object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    // returns whether the UIDesignRequiresCompatibility Info.plist property, which is used to indicate that the app is opting out of Liquid Glass, is set to true
    @_spi(STP) public class var liquidGlassOptedOut: Bool {
        return self.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool == true
    }
}
