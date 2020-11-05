//
//  STPConfirmPaymentMethodOptions.swift
//  Stripe
//
//  Created by Cameron Sabol on 1/10/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

/// Options to update the associated PaymentMethod during PaymentIntent confirmation.
/// - seealso: https://stripe.com/docs/api/payment_intents/confirm#confirm_payment_intent-payment_method_options
public class STPConfirmPaymentMethodOptions: NSObject {

  /// Options to update a Card PaymentMethod.
  /// - seealso: STPConfirmCardOptions
  @objc public var cardOptions: STPConfirmCardOptions?

  /// Options for an Alipay Payment Method.
  @objc public var alipayOptions: STPConfirmAlipayOptions?

  /// :nodoc:
  @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

  /// :nodoc:
  @objc public override var description: String {
    let props: [String] = [
      // Object
      String(format: "%@: %p", NSStringFromClass(type(of: self)), self),
      "alipay = \(String(describing: alipayOptions))",
      "card = \(String(describing: cardOptions))",
    ]
    return "<\(props.joined(separator: "; "))>"
  }
}

// MARK: - STPFormEncodable
extension STPConfirmPaymentMethodOptions: STPFormEncodable {
  @objc
  public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
    return [
      NSStringFromSelector(#selector(getter:alipayOptions)): "alipay",
      NSStringFromSelector(#selector(getter:cardOptions)): "card",
    ]
  }

  @objc
  public class func rootObjectName() -> String? {
    return "payment_method_options"
  }
}
