//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  NSLocale+STPSwizzling.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/17/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import ObjectiveC

class STPLocaleSwizzling {
    static var stpLocaleOverride: NSLocale?
    static var hasSwizzled: Bool = false

}

extension NSLocale {
    class func swizzleIfNeeded() {
        if !STPLocaleSwizzling.hasSwizzled {
            self.stp_swizzleClassMethod(#selector(getter: current), withReplacement: #selector(stp_current))
            self.stp_swizzleClassMethod(#selector(getter: autoupdatingCurrent), withReplacement: #selector(stp_autoUpdatingCurrent))
            self.stp_swizzleClassMethod(#selector(getter: system), withReplacement: #selector(stp_system))
            STPLocaleSwizzling.hasSwizzled = true
        }
    }

    class func stp_withLocale(as locale: NSLocale?, perform block: @escaping () -> Void) {
        swizzleIfNeeded()
        let currentLocale = NSLocale.current as NSLocale
        self.stp_setCurrentLocale(locale)
        block()
        self.stp_resetCurrentLocale()
        assert((currentLocale as Locale == NSLocale.current), "Failed to reset locale.")
    }

    class func stp_setCurrentLocale(_ locale: NSLocale?) {
        swizzleIfNeeded()
        STPLocaleSwizzling.stpLocaleOverride = locale
    }

    class func stp_resetCurrentLocale() {
        swizzleIfNeeded()
        self.stp_setCurrentLocale(nil)
    }

    @objc class func stp_current() -> NSLocale {
        return STPLocaleSwizzling.stpLocaleOverride ?? self.stp_current()
    }

    @objc class func stp_autoUpdatingCurrent() -> NSLocale {
        return STPLocaleSwizzling.stpLocaleOverride ?? self.stp_autoUpdatingCurrent()
    }

    @objc class func stp_system() -> NSLocale {
        return STPLocaleSwizzling.stpLocaleOverride ?? self.stp_system()
    }
}

extension NSObject {
    class func stp_swizzleClassMethod(_ original: Selector, withReplacement replacement: Selector) {
        let `class`: AnyClass? = object_getClass(self)
        let originalMethod = class_getClassMethod(self, original)
        let replacementMethod = class_getClassMethod(self, replacement)

        var addedMethod = false
        if let replacementMethod {
            addedMethod = class_addMethod(
                `class`,
                original,
                method_getImplementation(replacementMethod),
                method_getTypeEncoding(replacementMethod))
        }
        if addedMethod {
            if let originalMethod {
                class_replaceMethod(
                    `class`,
                    replacement,
                    method_getImplementation(originalMethod),
                    method_getTypeEncoding(originalMethod))
            }
        } else {
            if let originalMethod, let replacementMethod {
                method_exchangeImplementations(originalMethod, replacementMethod)
            }
        }
    }
}
