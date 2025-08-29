//
//  LiquidGlassDetector.swift
//  StripePaymentSheet
//
//  Created by David Estes on 8/4/25.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

// Our SDK runs inside a user's app, we can't explicitly opt into or out of the new "Liquid Glass" design.
// Instead, we'll do our best to detect which design to use, and adjust the default UI spacing and icons accordingly.
@_spi(STP) public class LiquidGlassDetector {
    /// A feature flag during development of iOS 26 features, only `true` for testing.
    @_spi(STP) public static var allowNewDesign: Bool = false
    @_spi(STP) public static var isEnabled: Bool {
        // If the app was built with Xcode 26 or later (which includes Swift compiler 6.2)...
        #if compiler(>=6.2)
        // And we're running on iOS 26 or later...
        if #available(iOS 26.0, *) {
            // And the app hasn't opted out of the new design...
            if !(Bundle.main.infoDictionary?["UIDesignRequiresCompatibility"] as? Bool ?? false)
                // ...and the feature flag is enabled...
                && allowNewDesign
            {
                // Then assume we're using the new design!
                return true
            }
        }
        #endif
        // Otherwise, use the old design
        return false
    }
}

// MARK: - UIView Liquid Glass helpers
@_spi(STP) extension UIView {
    @_spi(STP) public func ios26_applyCapsuleCornerConfiguration() {
        stpAssert(LiquidGlassDetector.isEnabled)
#if swift(>=6.2)
        cornerConfiguration = .capsule()
#endif
    }

    @_spi(STP) public func ios26_applyDefaultCornerConfiguration() {
        stpAssert(LiquidGlassDetector.isEnabled)
#if swift(>=6.2)
        cornerConfiguration = .uniformCorners(radius: 26)
#endif
    }
}
