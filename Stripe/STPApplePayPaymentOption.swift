//
//  STPApplePayPaymentOption.swift
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// An empty class representing that the user wishes to pay via Apple Pay. This can
/// be checked on an `STPPaymentContext`, e.g:
/// ```
/// if paymentContext.selectedPaymentOption is STPApplePayPaymentOption {
/// // Don't ask the user for their card number; they want to pay with apple pay.
/// }
/// ```
@objc public class STPApplePayPaymentOption: NSObject, STPPaymentOption {
  // MARK: - STPPaymentOption
  @objc public var image: UIImage {
    return STPImageLibrary.applePayCardImage()
  }

  @objc public var templateImage: UIImage {
    // No template for Apple Pay
    return STPImageLibrary.applePayCardImage()
  }

  @objc public var label: String {
    return STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
  }

  @objc public var isReusable: Bool {
    return true
  }

  // MARK: - Equality
  /// :nodoc:
  @objc
  public override func isEqual(_ object: Any?) -> Bool {
    return object is STPApplePayPaymentOption
  }

  /// :nodoc:
  @objc public override var hash: Int {
    return NSStringFromClass(STPApplePayPaymentOption.self).hash
  }
}
