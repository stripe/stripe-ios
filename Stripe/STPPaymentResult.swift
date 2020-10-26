//
//  STPPaymentResult.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// When you're using `STPPaymentContext` to request your user's payment details, this is the object that will be returned to your application when they've successfully made a payment.
/// See https://stripe.com/docs/mobile/ios/standard#submit-payment-intents.
public class STPPaymentResult: NSObject {
  /// The payment method that the user has selected. This may come from a variety of different payment methods, such as an Apple Pay payment or a stored credit card. - seealso: STPPaymentMethod.h
  /// If paymentMethod is nil, paymentMethodParams will be populated instead.
  @objc public private(set) var paymentMethod: STPPaymentMethod?
  /// The parameters for a payment method that the user has selected. This is
  /// populated for non-reusable payment methods, such as FPX and iDEAL. - seealso: STPPaymentMethodParams.h
  /// If paymentMethodParams is nil, paymentMethod will be populated instead.
  @objc public private(set) var paymentMethodParams: STPPaymentMethodParams?
  /// The STPPaymentOption that was used to initialize this STPPaymentResult, either an STPPaymentMethod or an STPPaymentMethodParams.

  @objc public weak var paymentOption: STPPaymentOption? {
    if paymentMethod != nil {
      return paymentMethod
    } else {
      return paymentMethodParams
    }
  }

  /// Initializes the payment result with a given payment option. This is invoked by `STPPaymentContext` internally; you shouldn't have to call it directly.
  @objc
  public init(paymentOption: STPPaymentOption?) {
    super.init()
    if paymentOption is STPPaymentMethod {
      paymentMethod = paymentOption as? STPPaymentMethod
    } else if paymentOption is STPPaymentMethodParams {
      paymentMethodParams = paymentOption as? STPPaymentMethodParams
    }
  }
}
