//
//  STPThreeDSFooterCustomization.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import Stripe3DS2
import UIKit

/// The Challenge view displays a footer with additional details that
/// expand when tapped. This object configures the appearance of that view.
public class STPThreeDSFooterCustomization: NSObject {
  /// The default settings.
  @objc
  public class func defaultSettings() -> STPThreeDSFooterCustomization {
    return STPThreeDSFooterCustomization()
  }

  internal var footerCustomization = STDSFooterCustomization.defaultSettings()
  /// The background color of the footer.
  /// Defaults to gray.

  @objc public var backgroundColor: UIColor {
    get {
      return footerCustomization.backgroundColor
    }
    set(backgroundColor) {
      footerCustomization.backgroundColor = backgroundColor
    }
  }

  /// The color of the chevron. Defaults to a dark gray.
  @objc public var chevronColor: UIColor {
    get {
      return footerCustomization.chevronColor
    }
    set(chevronColor) {
      footerCustomization.chevronColor = chevronColor
    }
  }

  /// The color of the heading text. Defaults to black.
  @objc public var headingTextColor: UIColor {
    get {
      return footerCustomization.headingTextColor
    }
    set(headingTextColor) {
      footerCustomization.headingTextColor = headingTextColor
    }
  }
  /// The font to use for the heading text.

  @objc public var headingFont: UIFont {
    get {
      return footerCustomization.headingFont
    }
    set(headingFont) {
      footerCustomization.headingFont = headingFont
    }
  }

  /// The font of the text.
  @objc public var font: UIFont? {
    get {
      return footerCustomization.font
    }
    set(font) {
      footerCustomization.font = font
    }
  }

  /// The color of the text.
  @objc public var textColor: UIColor? {
    get {
      return footerCustomization.textColor
    }
    set(textColor) {
      footerCustomization.textColor = textColor
    }
  }

}
