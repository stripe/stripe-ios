//
//  STPThreeDSLabelCustomization.swift
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

/// A customization object to use to configure the UI of a text label.
public class STPThreeDSLabelCustomization: NSObject {
  /// The default settings.
  @objc
  public class func defaultSettings() -> STPThreeDSLabelCustomization {
    return STPThreeDSLabelCustomization()
  }

  internal var labelCustomization = STDSLabelCustomization.defaultSettings()

  /// The font to use for heading text.

  @objc public var headingFont: UIFont {
    get {
      return labelCustomization.headingFont
    }
    set(headingFont) {
      labelCustomization.headingFont = headingFont
    }
  }
  /// The color of heading text. Defaults to black.

  @objc public var headingTextColor: UIColor {
    get {
      return labelCustomization.headingTextColor
    }
    set(headingTextColor) {
      labelCustomization.headingTextColor = headingTextColor
    }
  }

  /// The font to use for non-heading text.
  @objc public var font: UIFont? {
    get {
      return labelCustomization.font
    }
    set(font) {
      labelCustomization.font = font
    }
  }

  /// The color to use for non-heading text. Defaults to black.
  @objc public var textColor: UIColor? {
    get {
      return labelCustomization.textColor
    }
    set(textColor) {
      labelCustomization.textColor = textColor
    }
  }

}
