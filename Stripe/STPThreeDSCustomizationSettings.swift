//
//  STPThreeDSCustomizationSettings.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 5/30/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

import Stripe3DS2

/// `STPThreeDSCustomizationSettings` provides customization options for 3DS2 authentication flows in your app.
public class STPThreeDSCustomizationSettings: NSObject {
  /// Returns an `STPThreeDSCustomizationSettings` preconfigured with the default
  /// Stripe UI settings and a 10 minute `authenticationTimeout`.
  /// @deprecated Use STPThreeDSCustomizationSettings() instead. The default settings are the same.
  @available(*, deprecated, message: "Use STPThreeDSCustomizationSettings() instead of STPThreeDSCustomizationSettings.defaultSettings().")
  @objc
  public class func defaultSettings() -> STPThreeDSCustomizationSettings {
    return STPThreeDSCustomizationSettings()
  }
  
  /// `uiCustomization` can be used to provide custom UI settings for the authentication
  /// challenge screens presented during a Three Domain Secure authentication. For more information see
  /// our guide on supporting 3DS2 in your iOS application.
  /// Note: It's important to configure this object appropriately before calling any `STPPaymentHandler` APIs.
  /// The API makes a copy of the customization settings you provide; it ignores any subsequent changes you
  /// make to your `STPThreeDSUICustomization` instance.
  /// Defaults to `STPThreeDSUICustomization.defaultSettings()`.
  @objc public var uiCustomization = STPThreeDSUICustomization.defaultSettings()
  /// `authenticationTimeout` is the total time allowed for a user to complete a 3DS2 authentication
  /// interaction, in minutes.  This value *must* be at least 5 minutes.
  /// Defaults to 10 minutes.
  @objc public var authenticationTimeout = 10
}
