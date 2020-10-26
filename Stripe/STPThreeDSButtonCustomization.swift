//
//  STPThreeDSButtonCustomization.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import Stripe3DS2
import UIKit

/// An enum that defines the different types of buttons that are able to be customized.
@objc public enum STPThreeDSCustomizationButtonType: Int {
  /// The submit button type.
  case submit = 0
  /// The continue button type.
  case `continue` = 1
  /// The next button type.
  case next = 2
  /// The cancel button type.
  case cancel = 3
  /// The resend button type.
  case resend = 4
}

/// An enumeration of the case transformations that can be applied to the button's title
@objc public enum STPThreeDSButtonTitleStyle: Int {
  /// Default style, doesn't modify the title
  case `default`
  /// Applies localizedUppercaseString to the title
  case uppercase
  /// Applies localizedLowercaseString to the title
  case lowercase
  /// Applies localizedCapitalizedString to the title
  case sentenceCapitalized
}

/// A customization object to use to configure the UI of a button.
public class STPThreeDSButtonCustomization: NSObject {
  /// The default settings for the provided button type.
  @objc(defaultSettingsForButtonType:) public class func defaultSettings(
    for type: STPThreeDSCustomizationButtonType
  ) -> STPThreeDSButtonCustomization {
    let stdsButtonCustomization = STDSButtonCustomization.defaultSettings(
      for: STDSUICustomizationButtonType(rawValue: type.rawValue)!)
    let buttonCustomization = STPThreeDSButtonCustomization.init(
      backgroundColor: stdsButtonCustomization.backgroundColor,
      cornerRadius: stdsButtonCustomization.cornerRadius)
    buttonCustomization.buttonCustomization = stdsButtonCustomization
    return buttonCustomization
  }

  internal var buttonCustomization: STDSButtonCustomization

  /// Initializes an instance of STDSButtonCustomization with the given backgroundColor and colorRadius.
  @objc
  public init(backgroundColor: UIColor, cornerRadius: CGFloat) {
    buttonCustomization = STDSButtonCustomization(
      backgroundColor: backgroundColor, cornerRadius: cornerRadius)
    super.init()
  }

  /// The background color of the button.
  /// The default for .resend and .cancel is clear.
  /// The default for .submit, .continue, and .next is blue.

  @objc public var backgroundColor: UIColor {
    get {
      return buttonCustomization.backgroundColor
    }
    set(backgroundColor) {
      buttonCustomization.backgroundColor = backgroundColor
    }
  }
  /// The corner radius of the button. Defaults to 8.

  @objc public var cornerRadius: CGFloat {
    get {
      return buttonCustomization.cornerRadius
    }
    set(cornerRadius) {
      buttonCustomization.cornerRadius = cornerRadius
    }
  }
  /// The capitalization style of the button title.

  @objc public var titleStyle: STPThreeDSButtonTitleStyle {
    get {
      return STPThreeDSButtonTitleStyle(rawValue: buttonCustomization.titleStyle.rawValue)!
    }
    set(titleStyle) {
      buttonCustomization.titleStyle = STDSButtonTitleStyle(rawValue: titleStyle.rawValue)!
    }
  }
  /// The font of the title.

  @objc public var font: UIFont? {
    get {
      return buttonCustomization.font
    }
    set(font) {
      buttonCustomization.font = font
    }
  }
  /// The text color of the title.

  @objc public var textColor: UIColor? {
    get {
      return buttonCustomization.textColor
    }
    set(textColor) {
      buttonCustomization.textColor = textColor
    }
  }
}
