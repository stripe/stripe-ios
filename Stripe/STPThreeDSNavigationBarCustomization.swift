//
//  STPThreeDSNavigationBarCustomization.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

/// A customization object to use to configure a UINavigationBar.
public class STPThreeDSNavigationBarCustomization: NSObject {
    /// The default settings.
    @objc
    public class func defaultSettings() -> STPThreeDSNavigationBarCustomization {
        return STPThreeDSNavigationBarCustomization()
    }

    internal var navigationBarCustomization = STDSNavigationBarCustomization.defaultSettings()

    /// The tint color of the navigation bar background.
    /// Defaults to nil.

    @objc public var barTintColor: UIColor? {
        get {
            return navigationBarCustomization.barTintColor
        }
        set(barTintColor) {
            navigationBarCustomization.barTintColor = barTintColor
        }
    }
    /// The navigation bar style.
    /// Defaults to UIBarStyleDefault.
    /// @note This property controls the `UIStatusBarStyle`. Set this to `UIBarStyleBlack`
    /// to change the `statusBarStyle` to `UIStatusBarStyleLightContent` - even if you also set
    /// `barTintColor` to change the actual color of the navigation bar.

    @objc public var barStyle: UIBarStyle {
        get {
            return navigationBarCustomization.barStyle
        }
        set(barStyle) {
            navigationBarCustomization.barStyle = barStyle
        }
    }
    /// A Boolean value indicating whether the navigation bar is translucent or not.
    /// Defaults to YES.
    @objc public var translucent: Bool {
        get {
            return navigationBarCustomization.translucent
        }
        set(translucent) {
            navigationBarCustomization.translucent = translucent
        }
    }
    /// The text to display in the title of the navigation bar.
    /// Defaults to "Secure checkout".

    @objc public var headerText: String {
        get {
            return navigationBarCustomization.headerText
        }
        set(headerText) {
            navigationBarCustomization.headerText = headerText
        }
    }
    /// The text to display for the button in the navigation bar.
    /// Defaults to "Cancel".
    @objc public var buttonText: String {
        get {
            return navigationBarCustomization.buttonText
        }
        set(buttonText) {
            navigationBarCustomization.buttonText = buttonText
        }
    }
    /// The font to use for the title. Defaults to nil.
    @objc public var font: UIFont? {
        get {
            return navigationBarCustomization.font
        }
        set(font) {
            navigationBarCustomization.font = font
        }
    }
    /// The color to use for the title. Defaults to nil.
    @objc public var textColor: UIColor? {
        get {
            return navigationBarCustomization.textColor
        }
        set(textColor) {
            navigationBarCustomization.textColor = textColor
        }
    }
}
