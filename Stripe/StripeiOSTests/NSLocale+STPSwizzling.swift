//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  NSLocale+STPSwizzling.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 7/17/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation
import ObjectiveC

private var _stpLocaleOverride: NSLocale?

extension NSLocale {
    override class func load() {
        #warning("[Swiftify] failed to move the `dispatch_once()` block below to a static variable initializer")
        { [self] in
            self.stp_swizzleClassMethod(#selector(current), withReplacement: #selector(stp_current))
            self.stp_swizzleClassMethod(#selector(autoupdatingCurrent), withReplacement: #selector(stp_autoUpdatingCurrent))
            self.stp_swizzleClassMethod(#selector(system), withReplacement: #selector(stp_system))
        }

    }

    class func stp_withLocale(as locale: NSLocale?, perform block: @escaping () -> Void) {
        let currentLocale = NSLocale.current as NSLocale
        self.stp_setCurrentLocale(locale)
        block()
        self.stp_resetCurrentLocale()
        assert((currentLocale == NSLocale.current), "Failed to reset locale.")
    }

    class func stp_setCurrentLocale(_ locale: NSLocale?) {
        stpLocaleOverride = locale
    }

    class func stp_resetCurrentLocale() {
        self.stp_setCurrentLocale(nil)
    }

    @objc class func stp_current() -> Self {
        return stpLocaleOverride ?? self.stp_current()
    }

    @objc class func stp_autoUpdatingCurrent() -> Self {
        return stpLocaleOverride ?? self.stp_autoUpdatingCurrent()
    }

    @objc class func stp_system() -> Self {
        return stpLocaleOverride ?? self.stp_system()
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