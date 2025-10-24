//
//  LiquidGlassDetector.swift
//  StripePaymentSheet
//
//  Created by David Estes on 8/4/25.
//

import Foundation
import UIKit

@_spi(STP) public class LiquidGlassDetector {
    /// Whether or not the merchant's app (not MPE) has Liquid Glass enabled
    @_spi(STP) public static var isEnabledInMerchantApp: Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }
        return meetsCompilerRequirements && !hasOptedOut
    }

    /// Whether the app was built with Xcode 26 or later (which includes Swift compiler 6.2)
    @_spi(STP) public static var meetsCompilerRequirements: Bool {
        #if compiler(>=6.2)
        return true
        #else
        return false
        #endif
    }

    /// Whether the app hasn't opted out of the new design
    @_spi(STP) public static var hasOptedOut: Bool {
        if let optOutFlag = Bundle.main.infoDictionary?["UIDesignRequiresCompatibility"] as? Bool {
            return optOutFlag
        }
        return false
    }
}

// MARK: - UIView Liquid Glass helpers
extension UIView {
    @_spi(STP) public func ios26_applyCapsuleCornerConfiguration() {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            cornerConfiguration = .capsule()
        }
#endif
    }

    @_spi(STP) public func ios26_applyDefaultCornerConfiguration() {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            cornerConfiguration = .uniformCorners(radius: 26)
        }
#endif
    }

    /// Convenience method that returns whether or not `cornerConfiguration` was set.
    @_spi(STP) public var didSetCornerConfiguration: Bool {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            return UIView.plainUIView.cornerConfiguration != cornerConfiguration
        }
#endif
        return false
    }

    // Compiler flag here is just to satisfy dead code checker, on Xcode 25 it's unused
#if compiler(>=6.2)
    /// Just exists to avoid creating one every time in `didSetCornerConfiguration`
    static var plainUIView = UIView()
#endif
}

// MARK: - Button Liquid Glass helpers
extension UIButton {
    @_spi(STP) public func ios26_applyGlassConfiguration() {
        assert(LiquidGlassDetector.isEnabledInMerchantApp)
        // These checks are a convenience because .glass is only available on iOS (not visionOS)
        // when compiling with XCode 26
#if compiler(>=6.2)
        #if !os(visionOS)
        if #available(iOS 26.0, *) {
            configuration = .glass()
        }
        #endif
#endif
    }
}
// MARK: - UIView helpers
extension UIView {
    @_spi(STP) public enum CornerStyle {
        case capsule
        case uniform
    }

    /// A convenience method that looks at `appearance.cornerRadius` and applies it or, if `nil`, handles what the default value should be.
    @_spi(STP) public func applyCornerRadius(appearance: ElementsAppearance, ios26DefaultCornerStyle: CornerStyle = .uniform) {
        // If corner radius was set, just use that
        if let cornerRadius = appearance.cornerRadius {
            layer.cornerRadius = cornerRadius
            return
        }
        // Otherwise, use the default value, which depends if we're iOS 26+ or not
        if LiquidGlassDetector.isEnabledInMerchantApp {
            switch ios26DefaultCornerStyle {
            case .capsule:
                ios26_applyCapsuleCornerConfiguration()
            case .uniform:
                ios26_applyDefaultCornerConfiguration()
            }
        } else {
            layer.cornerRadius = ElementsUI.defaultCornerRadius
        }
    }
}
