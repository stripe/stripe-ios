//
//  STPThreeDSUICustomization.swift
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

/// The `STPThreeDSUICustomization` provides configuration for UI elements displayed during 3D Secure authentication.
/// Note: It's important to configure this object appropriately before calling any `STPPaymentHandler` APIs.
/// The API makes a copy of the customization settings you provide; it ignores any subsequent changes you
/// make to your `STPThreeDSUICustomization` instance.
/// - seealso: https://stripe.com/docs/mobile/ios/authentication
public class STPThreeDSUICustomization: NSObject {
  /// The default settings.  See individual properties for their default values.
  @objc
  public class func defaultSettings() -> STPThreeDSUICustomization {
    return STPThreeDSUICustomization()
  }

  internal var uiCustomization = STDSUICustomization.defaultSettings()

  private var _navigationBarCustomization = STPThreeDSNavigationBarCustomization.defaultSettings()
  /// Provides custom settings for the UINavigationBar of all UIViewControllers displayed during 3D Secure authentication.
  /// The default is `STPThreeDSNavigationBarCustomization.defaultSettings()`.
  @objc public var navigationBarCustomization: STPThreeDSNavigationBarCustomization {
    get {
      _navigationBarCustomization
    }
    set(navigationBarCustomization) {
      _navigationBarCustomization = navigationBarCustomization
      uiCustomization.navigationBarCustomization =
        navigationBarCustomization.navigationBarCustomization
    }
  }

  private var _labelCustomization = STPThreeDSLabelCustomization.defaultSettings()
  /// Provides custom settings for labels.
  /// The default is `STPThreeDSLabelCustomization.defaultSettings()`.
  @objc public var labelCustomization: STPThreeDSLabelCustomization {
    get {
      _labelCustomization
    }
    set(labelCustomization) {
      _labelCustomization = labelCustomization
      uiCustomization.labelCustomization = labelCustomization.labelCustomization
    }
  }

  private var _textFieldCustomization = STPThreeDSTextFieldCustomization.defaultSettings()
  /// Provides custom settings for text fields.
  /// The default is `STPThreeDSTextFieldCustomization.defaultSettings()`.
  @objc public var textFieldCustomization: STPThreeDSTextFieldCustomization {
    get {
      _textFieldCustomization
    }
    set(textFieldCustomization) {
      _textFieldCustomization = textFieldCustomization
      uiCustomization.textFieldCustomization = textFieldCustomization.textFieldCustomization
    }
  }

  /// The primary background color of all UIViewControllers displayed during 3D Secure authentication.
  /// Defaults to white.
  @objc public var backgroundColor: UIColor {
    get {
      return uiCustomization.backgroundColor
    }
    set(backgroundColor) {
      uiCustomization.backgroundColor = backgroundColor
    }
  }

  private var _footerCustomization = STPThreeDSFooterCustomization.defaultSettings()
  /// Provides custom settings for the footer the challenge view can display containing additional details.
  /// The default is `STPThreeDSFooterCustomization.defaultSettings()`.
  @objc public var footerCustomization: STPThreeDSFooterCustomization {
    get {
      _footerCustomization
    }
    set(footerCustomization) {
      _footerCustomization = footerCustomization
      uiCustomization.footerCustomization = footerCustomization.footerCustomization
    }
  }

  /// Sets a given button customization for the specified type.
  /// - Parameters:
  ///   - buttonCustomization: The buttom customization to use.
  ///   - buttonType: The type of button to use the customization for.
  @objc(setButtonCustomization:forType:) public func setButtonCustomization(
    _ buttonCustomization: STPThreeDSButtonCustomization,
    for buttonType: STPThreeDSCustomizationButtonType
  ) {
    buttonCustomizationDictionary[NSNumber(value: buttonType.rawValue)] = buttonCustomization
    self.uiCustomization.setButton(
      buttonCustomization.buttonCustomization,
      for: STDSUICustomizationButtonType(rawValue: buttonType.rawValue)!)
  }

  /// Retrieves a button customization object for the given button type.
  /// - Parameter buttonType: The button type to retrieve a customization object for.
  /// - Returns: A button customization object, or the default if none was set.
  /// - seealso: STPThreeDSButtonCustomization
  @objc(buttonCustomizationForButtonType:) public func buttonCustomization(
    for buttonType: STPThreeDSCustomizationButtonType
  ) -> STPThreeDSButtonCustomization {
    return (buttonCustomizationDictionary[NSNumber(value: buttonType.rawValue)])!
  }

  private var _selectionCustomization = STPThreeDSSelectionCustomization.defaultSettings()
  /// Provides custom settings for radio buttons and checkboxes.
  /// The default is `STPThreeDSSelectionCustomization.defaultSettings()`.
  @objc public var selectionCustomization: STPThreeDSSelectionCustomization {
    get {
      _selectionCustomization
    }
    set(selectionCustomization) {
      _selectionCustomization = selectionCustomization
      uiCustomization.selectionCustomization = selectionCustomization.selectionCustomization
    }
  }
  // MARK: - Progress View

  /// The style of `UIActivityIndicatorView`s displayed.
  /// This should contrast with `backgroundColor`.  Defaults to gray.

  @objc public var activityIndicatorViewStyle: UIActivityIndicatorView.Style {
    get {
      return uiCustomization.activityIndicatorViewStyle
    }
    set(activityIndicatorViewStyle) {
      uiCustomization.activityIndicatorViewStyle = activityIndicatorViewStyle
    }
  }

  /// The style of the `UIBlurEffect` displayed underneath the `UIActivityIndicatorView`.
  /// Defaults to `UIBlurEffectStyleLight`.
  @objc public var blurStyle: UIBlurEffect.Style {
    get {
      return uiCustomization.blurStyle
    }
    set(blurStyle) {
      uiCustomization.blurStyle = blurStyle
    }
  }

  private var buttonCustomizationDictionary: [NSNumber: STPThreeDSButtonCustomization]

  /// :nodoc:
  @objc
  public override init() {
    // Initialize defaults for all properties
    let nextButton = STPThreeDSButtonCustomization.defaultSettings(for: .next)
    let cancelButton = STPThreeDSButtonCustomization.defaultSettings(for: .cancel)
    let resendButton = STPThreeDSButtonCustomization.defaultSettings(for: .resend)
    let submitButton = STPThreeDSButtonCustomization.defaultSettings(for: .submit)
    let continueButton = STPThreeDSButtonCustomization.defaultSettings(for: .continue)
    buttonCustomizationDictionary = [
      NSNumber(value: STPThreeDSCustomizationButtonType.next.rawValue): nextButton,
      NSNumber(value: STPThreeDSCustomizationButtonType.cancel.rawValue): cancelButton,
      NSNumber(value: STPThreeDSCustomizationButtonType.resend.rawValue): resendButton,
      NSNumber(value: STPThreeDSCustomizationButtonType.submit.rawValue): submitButton,
      NSNumber(value: STPThreeDSCustomizationButtonType.continue.rawValue): continueButton,
    ]

    // Initialize the underlying STDS class we are wrapping
    uiCustomization = STDSUICustomization()
    uiCustomization.setButton(nextButton.buttonCustomization, for: .next)
    uiCustomization.setButton(cancelButton.buttonCustomization, for: .cancel)
    uiCustomization.setButton(resendButton.buttonCustomization, for: .resend)
    uiCustomization.setButton(submitButton.buttonCustomization, for: .submit)
    uiCustomization.setButton(continueButton.buttonCustomization, for: .continue)

    super.init()

    uiCustomization.footerCustomization = footerCustomization.footerCustomization
    uiCustomization.labelCustomization = labelCustomization.labelCustomization
    uiCustomization.navigationBarCustomization =
      navigationBarCustomization.navigationBarCustomization
    uiCustomization.selectionCustomization = selectionCustomization.selectionCustomization
    uiCustomization.textFieldCustomization = textFieldCustomization.textFieldCustomization

  }
}
