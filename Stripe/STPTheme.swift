//
//  STPTheme.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/3/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

/// STPTheme objects can be used to visually style Stripe-provided UI. See https://stripe.com/docs/mobile/ios/standard#theming for more information.
final public class STPTheme: NSObject {

  /// The default theme used by all Stripe UI. All themable UI classes, such as `STPAddCardViewController`, have one initializer that takes a `theme` and one that does not. If you use the one that does not, the default theme will be used to customize that view controller's appearance.
  @objc public static let defaultTheme = STPTheme()

  /// The primary background color of the theme. This will be used as the `backgroundColor` for any views with this theme.
  @objc public var primaryBackgroundColor: UIColor = STPThemeDefaultPrimaryBackgroundColor

  /// The secondary background color of this theme. This will be used as the `backgroundColor` for any supplemental views inside a view with this theme - for example, a `UITableView` will set it's cells' background color to this value.
  @objc public var secondaryBackgroundColor: UIColor = STPThemeDefaultSecondaryBackgroundColor

  /// This color is automatically derived by reducing the alpha of the `primaryBackgroundColor` and is used as a section border color in table view cells.
  @objc public var tertiaryBackgroundColor: UIColor {
    let colorBlock: STPColorBlock = {
      var hue: CGFloat = 0
      var saturation: CGFloat = 0
      var brightness: CGFloat = 0
      var alpha: CGFloat = 0
      self.primaryBackgroundColor.getHue(
        &hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

      return UIColor(hue: hue, saturation: saturation, brightness: brightness - 0.09, alpha: alpha)
    }
    if #available(iOS 13.0, *) {
      return UIColor(dynamicProvider: { _ in
        return colorBlock()
      })
    } else {
      return colorBlock()
    }
  }

  /// This color is automatically derived by reducing the brightness of the `primaryBackgroundColor` and is used as a separator color in table view cells.
  @objc public var quaternaryBackgroundColor: UIColor {
    let colorBlock: STPColorBlock = {
      var hue: CGFloat = 0
      var saturation: CGFloat = 0
      var brightness: CGFloat = 0
      var alpha: CGFloat = 0
      self.primaryBackgroundColor.getHue(
        &hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

      return UIColor(hue: hue, saturation: saturation, brightness: brightness - 0.03, alpha: alpha)
    }
    if #available(iOS 13.0, *) {
      return UIColor(dynamicProvider: { _ in
        return colorBlock()
      })
    } else {
      return colorBlock()
    }
  }

  /// The primary foreground color of this theme. This will be used as the text color for any important labels in a view with this theme (such as the text color for a text field that the user needs to fill out).
  @objc public var primaryForegroundColor: UIColor = STPThemeDefaultPrimaryForegroundColor

  /// The secondary foreground color of this theme. This will be used as the text color for any supplementary labels in a view with this theme (such as the placeholder color for a text field that the user needs to fill out).
  @objc public var secondaryForegroundColor: UIColor = STPThemeDefaultSecondaryForegroundColor

  /// This color is automatically derived from the `secondaryForegroundColor` with a lower alpha component, used for disabled text.
  @objc public var tertiaryForegroundColor: UIColor {
    if #available(iOS 13.0, *) {
      return UIColor(dynamicProvider: { _ in
        return self.primaryForegroundColor.withAlphaComponent(0.25)
      })
    } else {
      return primaryForegroundColor.withAlphaComponent(0.25)
    }
  }

  /// The accent color of this theme - it will be used for any buttons and other elements on a view that are important to highlight.
  @objc public var accentColor: UIColor = STPThemeDefaultAccentColor

  /// The error color of this theme - it will be used for rendering any error messages or views.
  @objc public var errorColor: UIColor = STPThemeDefaultErrorColor

  /// The font to be used for all views using this theme. Make sure to select an appropriate size.
  @objc public var font: UIFont {
    set {
      _font = newValue
    }
    get {
      if let _font = _font {
        return _font
      } else {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return fontMetrics.scaledFont(for: STPThemeDefaultFont)
      }
    }
  }
  private var _font: UIFont?

  /// The medium-weight font to be used for all bold text in views using this theme. Make sure to select an appropriate size.
  @objc public var emphasisFont: UIFont {
    set {
      _emphasisFont = newValue
    }
    get {
      if let _emphasisFont = _emphasisFont {
        return _emphasisFont
      } else {
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        return fontMetrics.scaledFont(for: STPThemeDefaultMediumFont)
      }
    }
  }
  private var _emphasisFont: UIFont?

  /// The navigation bar style to use for any view controllers presented modally
  /// by the SDK. The default value will be determined based on the brightness
  /// of the theme's `secondaryBackgroundColor`.
  @objc public var barStyle: UIBarStyle {
    set {
      _barStyle = newValue
    }
    get {
      if let _barStyle = _barStyle {
        return _barStyle
      } else {
        return barStyle(for: secondaryBackgroundColor)
      }
    }
  }
  private var _barStyle: UIBarStyle?

  /// A Boolean value indicating whether the navigation bar for any view controllers
  /// presented modally by the SDK should be translucent. The default value is YES.
  @objc public var translucentNavigationBar = true

  /// This font is automatically derived from the font, with a slightly lower point size, and will be used for supplementary labels.
  @objc public var smallFont: UIFont {
    return font.withSize(max(font.pointSize - 2, 1))
  }

  /// This font is automatically derived from the font, with a larger point size, and will be used for large labels such as SMS code entry.
  @objc public var largeFont: UIFont {
    return font.withSize(font.pointSize + 15)
  }

  private func barStyle(for color: UIColor) -> UIBarStyle {
    if STPColorUtils.colorIsBright(color) {
      return .default
    } else {
      return .black
    }
  }
}

extension STPTheme: NSCopying {
  /// :nodoc:
  @objc
  public func copy(with zone: NSZone? = nil) -> Any {
    let otherTheme = STPTheme()
    otherTheme.primaryBackgroundColor = primaryBackgroundColor
    otherTheme.secondaryBackgroundColor = secondaryBackgroundColor
    otherTheme.primaryForegroundColor = primaryForegroundColor
    otherTheme.secondaryForegroundColor = secondaryForegroundColor
    otherTheme.accentColor = accentColor
    otherTheme.errorColor = errorColor
    otherTheme.translucentNavigationBar = translucentNavigationBar
    otherTheme._font = _font
    otherTheme._emphasisFont = _emphasisFont
    otherTheme._barStyle = _barStyle

    return otherTheme
  }
}

private typealias STPColorBlock = () -> UIColor

// MARK: Default Colors

private var STPThemeDefaultPrimaryBackgroundColor: UIColor {
  if #available(iOS 13.0, *) {
    return .secondarySystemBackground
  } else {
    return UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 245.0 / 255.0, alpha: 1)
  }
}

private var STPThemeDefaultSecondaryBackgroundColor: UIColor {
  if #available(iOS 13.0, *) {
    return .systemBackground
  } else {
    return .white
  }
}

private var STPThemeDefaultPrimaryForegroundColor: UIColor {
  if #available(iOS 13.0, *) {
    return .label
  } else {
    return UIColor(red: 43.0 / 255.0, green: 43.0 / 255.0, blue: 45.0 / 255.0, alpha: 1)
  }
}

private var STPThemeDefaultSecondaryForegroundColor: UIColor {
  if #available(iOS 13.0, *) {
    return .secondaryLabel
  } else {
    return UIColor(red: 142.0 / 255.0, green: 142.0 / 255.0, blue: 147.0 / 255.0, alpha: 1)
  }
}

private var STPThemeDefaultAccentColor: UIColor {
  if #available(iOS 13.0, *) {
    return .systemBlue
  } else {
    return UIColor(red: 0.0 / 255.0, green: 122.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
  }
}

private var STPThemeDefaultErrorColor: UIColor {
  if #available(iOS 13.0, *) {
    return .systemRed
  } else {
    return UIColor(red: 255.0 / 255.0, green: 72.0 / 255.0, blue: 68.0 / 255.0, alpha: 1)
  }
}

// MARK: Default Fonts
private let STPThemeDefaultFont = UIFont.systemFont(ofSize: 17)
private let STPThemeDefaultMediumFont = UIFont.systemFont(ofSize: 17, weight: .medium)
