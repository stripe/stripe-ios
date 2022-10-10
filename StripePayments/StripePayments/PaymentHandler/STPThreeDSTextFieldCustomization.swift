//
//  STPThreeDSTextFieldCustomization.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/18/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

#if canImport(Stripe3DS2)
    import Stripe3DS2
#endif

/// A customization object to use to configure the UI of a text field.
public class STPThreeDSTextFieldCustomization: NSObject {
    /// The default settings.
    @objc
    public class func defaultSettings() -> STPThreeDSTextFieldCustomization {
        return STPThreeDSTextFieldCustomization()
    }

    internal var textFieldCustomization = STDSTextFieldCustomization.defaultSettings()

    /// The border width of the text field. Defaults to 2.
    @objc public var borderWidth: CGFloat {
        get {
            return textFieldCustomization.borderWidth
        }
        set(borderWidth) {
            textFieldCustomization.borderWidth = borderWidth
        }
    }

    /// The color of the border of the text field. Defaults to clear.
    @objc public var borderColor: UIColor {
        get {
            return textFieldCustomization.borderColor
        }
        set(borderColor) {
            textFieldCustomization.borderColor = borderColor
        }
    }

    /// The corner radius of the edges of the text field. Defaults to 8.
    @objc public var cornerRadius: CGFloat {
        get {
            return textFieldCustomization.cornerRadius
        }
        set(cornerRadius) {
            textFieldCustomization.cornerRadius = cornerRadius
        }
    }
    /// The appearance of the keyboard. Defaults to UIKeyboardAppearanceDefault.

    @objc public var keyboardAppearance: UIKeyboardAppearance {
        get {
            return textFieldCustomization.keyboardAppearance
        }
        set(keyboardAppearance) {
            textFieldCustomization.keyboardAppearance = keyboardAppearance
        }
    }
    /// The color of the placeholder text. Defaults to light gray.

    @objc public var placeholderTextColor: UIColor {
        get {
            return textFieldCustomization.placeholderTextColor
        }
        set(placeholderTextColor) {
            textFieldCustomization.placeholderTextColor = placeholderTextColor
        }
    }

    /// The font to use for text.
    @objc public var font: UIFont? {
        get {
            return textFieldCustomization.font
        }
        set(font) {
            textFieldCustomization.font = font
        }
    }
    /// The color to use for the text. Defaults to black.
    @objc public var textColor: UIColor? {
        get {
            return textFieldCustomization.textColor
        }
        set(textColor) {
            textFieldCustomization.textColor = textColor
        }
    }
}
